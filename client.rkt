#lang racket
(require net/url
         net/uri-codec
         net/http-client
         json
         racket/list
         racket/contract
         racket/format
         racket/match
         "private/util.rkt")

(provide
 (contract-out
  [make-opencage-client (->* (string?) (#:defaults any/c #:auto-throttle? boolean? #:extra-headers any/c) opencage-client?)]
  [opencage-client? (-> any/c boolean?)]
    [opencage-geocode (->* (opencage-client? string?) (#:params (or/c hash? list?)) oc-response?)]
    [opencage-reverse (->* (opencage-client? real? real?) (#:params (or/c hash? list?)) oc-response?)]
  [opencage-client-rate-remaining (-> opencage-client? (or/c exact-nonnegative-integer? #f))]
  [opencage-client-rate-reset-seconds (-> opencage-client? (or/c exact-nonnegative-integer? #f))]
  [opencage-version (-> string?)]
  [oc-response? (-> any/c boolean?)]
  [oc-response-data (-> oc-response? hash?)]
  [oc-response-status-code (-> oc-response? exact-nonnegative-integer?)]
  [oc-response-rate-limit-remaining (-> oc-response? (or/c exact-nonnegative-integer? #f))]
  [oc-response-rate-limit-reset (-> oc-response? (or/c exact-nonnegative-integer? #f))]
  [exn:fail:opencage? (-> any/c boolean?)]
  [exn:fail:opencage-status-code (-> exn:fail:opencage? exact-nonnegative-integer?)]
  [exn:fail:opencage-body (-> exn:fail:opencage? any/c)]))

(struct opencage-client (api-key defaults auto-throttle? sem state extra-headers) #:transparent)
(struct oc-response (data status-code rate-limit-remaining rate-limit-reset raw) #:transparent)
(struct exn:fail:opencage exn:fail (status-code body) #:transparent)

(define HOST "api.opencagedata.com")
(define PATH "/geocode/v1/json")

(define (base-url) (string-append "https://" HOST PATH))

(define OPCAGE-VERSION "1.0.7")

(define (opencage-version) OPCAGE-VERSION)

(define (default-user-agent)
  (format "racket-opencage/~a (+https://opencagedata.com; +https://github.com/opencagedata)" OPCAGE-VERSION))

(define (make-opencage-client api-key #:defaults [defaults (hash)] #:auto-throttle? [auto-throttle? #t] #:extra-headers [extra-headers '()])
  (unless (and (string? api-key) (positive? (string-length api-key)))
    (error 'make-opencage-client "API key must be a non-empty string"))
  (opencage-client api-key (normalize-params (kvs->hash defaults)) auto-throttle? (make-semaphore 1) (box (hash 'remaining #f 'reset #f)) extra-headers))

(define (opencage-client-rate-remaining c)
  (hash-ref (unbox (opencage-client-state c)) 'remaining #f))
(define (opencage-client-rate-reset-seconds c)
  (hash-ref (unbox (opencage-client-state c)) 'reset #f))

(define (opencage-geocode client query #:params [params (hash)])
  (request client (hash 'q query) params))

(define (opencage-reverse client lat lon #:params [params (hash)])
  (request client (hash 'q (format "~a,~a" lat lon)) params))

(define (merge-params client base user)
  (define defaults (opencage-client-defaults client))
  (define base* (normalize-params (kvs->hash base)))
  (define user* (normalize-params (kvs->hash user)))
  (define (apply-over a b)
    (for/fold ([acc a]) ([(k v) (in-hash b)]) (hash-set acc k v)))
  (apply-over (apply-over defaults base*) user*))

(define (hash->query h)
  (string-join
   (for/list ([(k v) (in-hash h)])
     (format "~a=~a" (uri-encode (symbol->string k)) (uri-encode (~a v))))
   "&"))

(define (raise-opencage-error who msg status body)
  (raise (exn:fail:opencage (format "~a: ~a" who msg)
                            (current-continuation-marks)
                            status body)))

(define (bytes->status-code b)
  (define s (bytes->string/utf-8 b))
  (cond
    [(regexp-match #px"^[0-9]{3}$" s) => (λ(m) (string->number (car m)))]
    [(regexp-match #px"\b([0-9]{3})\b" s) => (λ(m) (string->number (cadr m)))]
    [else #f]))

;; Perform HTTP GET capturing status & headers using http-sendrecv.
;; We manually append the query string to the fixed path.
(define (build-request-headers client)
  ;; http-sendrecv expects each element to be a full header line "Name: value"
  (define base-lines
    (list (format "User-Agent: ~a" (default-user-agent))
          "Accept: application/json"
          "Accept-Encoding: identity"))
  (define extra-lines
    (for/list ([p (in-list (opencage-client-extra-headers client))]
               #:when p)
      (match p
        [(? string? s) s]
        [(cons k v) (format "~a: ~a" k v)]
        [_ (format "X-Ignored: ~a" p)])))
  (append base-lines extra-lines))

(define (do-request client params)
  (define qs (hash->query params))
  (define path+query (if (string=? qs "") PATH (string-append PATH "?" qs)))
  (with-handlers ([exn:fail? (λ(e)
                               (raise-opencage-error 'request (format "network error: ~a" (exn-message e)) 0 (hash 'error (exn-message e))))])
  (define-values (status headers in)
    (http-sendrecv HOST path+query #:port 443 #:headers (build-request-headers client) #:ssl? #t))
    (define body (port->string in))
    (close-input-port in)
  (values body (string-append (base-url) (if (string=? qs "") "" (string-append "?" qs))) status headers)))

(define (request client base user)
  ;; pre-call throttle if needed
  (when (opencage-client-auto-throttle? client)
    (semaphore-wait (opencage-client-sem client))
    (with-handlers ([exn:fail? (λ(e) (semaphore-post (opencage-client-sem client)) (raise e))])
      (define st (unbox (opencage-client-state client)))
      (define remaining (hash-ref st 'remaining #f))
      (define reset (hash-ref st 'reset #f))
      (when (and remaining reset (<= remaining 0) (exact-nonnegative-integer? reset) (> reset 0))
        ;; Interpret reset header as epoch seconds when in the future, else treat as delta seconds
        (define now (inexact->exact (floor (current-seconds))))
        (define wait-secs (if (> reset now) (- reset now) reset))
        (when (> wait-secs 0)
          (sleep (min wait-secs 60)))) ; cap single sleep to 60s to avoid very long block
      (semaphore-post (opencage-client-sem client))))
  (define merged (merge-params client base user))
  (define all (hash-set merged 'key (opencage-client-api-key client)))
  (define-values (body url status-bytes headers) (do-request client all))
  (define js
    (with-handlers ([exn:fail? (λ(e)
                                 (raise-opencage-error 'request
                                                       (format "JSON parse error: ~a" (exn-message e))
                                                       0
                                                       (hash 'raw body)))])
      (string->jsexpr body)))
  (define http-status (or (bytes->status-code status-bytes) 200))
  (define status-code-raw (hash-ref (hash-ref js 'status (hash)) 'code http-status))
  (define status-code (if (number? status-code-raw) status-code-raw http-status))
  (when (and (number? http-status) (or (not (= http-status 200)) (not (= status-code 200))))
    (define msg (or (hash-ref (hash-ref js 'status (hash)) 'message #f)
                    (and (string? body) (substring body 0 (min 200 (string-length body))))
                    ""))
    (raise-opencage-error 'request (format "HTTP ~a ~a" http-status msg) http-status js))
  (define rh (headers->hash headers))
  (define rl-rem (string->number/nullable (hash-ref rh 'x-ratelimit-remaining #f)))
  (define rl-reset (string->number/nullable (hash-ref rh 'x-ratelimit-reset #f)))
  ;; update client state
  (semaphore-wait (opencage-client-sem client))
  (set-box! (opencage-client-state client)
            (hash 'remaining rl-rem 'reset rl-reset))
  (semaphore-post (opencage-client-sem client))
  ;; Non-200 handled earlier.
  (oc-response js status-code rl-rem rl-reset (hash 'headers rh 'raw body 'url url)))

;; Convert raw header list from http-sendrecv into a symbol-key hash preserving case.
(define (headers->hash headers)
  (for/hash ([h (in-list headers)])
    (match h
      [(cons field value)
       (define sym (string->symbol (string-downcase (bytes->string/utf-8 field))))
       (values sym (bytes->string/utf-8 value))]
      [_ (values 'unknown "")])))

(define (string->number/nullable v)
  (and v (string->number (~a v))))
