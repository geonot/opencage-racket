1201
((3) 0 () 3 ((q lib "opencage/main.rkt") (q 1019 . 11) (q 1666 . 4)) () (h ! (equal) ((c def c (c (? . 0) q exn:fail:opencage-body)) c (? . 2)) ((c def c (c (? . 0) q oc-response-rate-limit-reset)) c (? . 1)) ((c def c (c (? . 0) q oc-response?)) c (? . 1)) ((c def c (c (? . 0) q oc-response-status-code)) c (? . 1)) ((c def c (c (? . 0) q struct:oc-response)) c (? . 1)) ((c def c (c (? . 0) q oc-response-rate-limit-remaining)) c (? . 1)) ((c def c (c (? . 0) q oc-response-raw)) c (? . 1)) ((c def c (c (? . 0) q make-opencage-client)) q (0 . 10)) ((c def c (c (? . 0) q opencage-version)) q (1795 . 2)) ((c def c (c (? . 0) q oc-response-data)) c (? . 1)) ((c def c (c (? . 0) q exn:fail:opencage?)) c (? . 2)) ((c def c (c (? . 0) q opencage-reverse)) q (693 . 9)) ((c def c (c (? . 0) q opencage-client-rate-remaining)) q (1426 . 4)) ((c def c (c (? . 0) q oc-response)) c (? . 1)) ((c def c (c (? . 0) q opencage-client-rate-reset-seconds)) q (1544 . 4)) ((c def c (c (? . 0) q exn:fail:opencage)) c (? . 2)) ((c def c (c (? . 0) q struct:exn:fail:opencage)) c (? . 2)) ((c def c (c (? . 0) q exn:fail:opencage-status-code)) c (? . 2)) ((c def c (c (? . 0) q opencage-geocode)) q (429 . 7))))
procedure
(make-opencage-client  api-key                         
                      [#:defaults defaults             
                       #:auto-throttle? auto-throttle? 
                       #:extra-headers extra-headers]) 
 -> opencage-client?
  api-key : string?
  defaults : (or/c hash? list?) = (hash)
  auto-throttle? : boolean? = #t
  extra-headers : (listof any/c) = '()
procedure
(opencage-geocode  client                
                   query                 
                  [#:params params]) -> oc-response?
  client : opencage-client?
  query : string?
  params : (or/c hash? list?) = (hash)
procedure
(opencage-reverse  client                
                   lat                   
                   lon                   
                  [#:params params]) -> oc-response?
  client : opencage-client?
  lat : real?
  lon : real?
  params : (or/c hash? list?) = (hash)
struct
(struct oc-response (data
                     status-code
                     rate-limit-remaining
                     rate-limit-reset
                     raw))
  data : hash?
  status-code : exact-nonnegative-integer?
  rate-limit-remaining : (or/c exact-nonnegative-integer? #f)
  rate-limit-reset : (or/c exact-nonnegative-integer? #f)
  raw : hash?
procedure
(opencage-client-rate-remaining c)
 -> (or/c exact-nonnegative-integer? #f)
  c : opencage-client?
procedure
(opencage-client-rate-reset-seconds c)
 -> (or/c exact-nonnegative-integer? #f)
  c : opencage-client?
struct
(struct exn:fail:opencage exn:fail (status-code body))
  status-code : exact-nonnegative-integer?
  body : any/c
procedure
(opencage-version) -> string?
