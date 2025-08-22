#lang racket
(require rackunit opencage)

(define api-key (getenv "OPENCAGE_API_KEY"))

(test-case "client construction"
  (define c (make-opencage-client (or api-key "DUMMY") #:defaults '((language . "en") (no_dedupe . #t))))
  (check-true (opencage-client? c)))

(when api-key
  (test-case "forward geocode basic"
    (define c (make-opencage-client api-key))
    (define r (opencage-geocode c "Berlin" #:params '(limit 1)))
    (check-equal? (oc-response-status-code r) 200)
    (check-true (hash-has-key? (oc-response-data r) 'results)))
  (test-case "reverse geocode basic"
    (define c (make-opencage-client api-key))
    (define r (opencage-reverse c 52.5200 13.4050 #:params '((limit . 1))))
    (check-equal? (oc-response-status-code r) 200)
    (check-true (hash-has-key? (oc-response-data r) 'results)))
  (test-case "rate limit tracking (if headers present)"
    (define c (make-opencage-client api-key))
    (define r (opencage-geocode c "Paris" #:params '((limit . 1))))
    (define resp-remaining (oc-response-rate-limit-remaining r))
    (define client-remaining (opencage-client-rate-remaining c))
    ;; If headers provided by API they should be numbers >= 0 and match.
    (when (and resp-remaining client-remaining)
      (check-equal? resp-remaining client-remaining)
      (check-true (exact-nonnegative-integer? resp-remaining)))))

(unless api-key
  (displayln "Skipping network tests (no OPENCAGE_API_KEY set)"))
