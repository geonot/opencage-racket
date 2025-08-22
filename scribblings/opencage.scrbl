#lang scribble/manual
@(require scribble/eval racket)
@(define the-eval (make-base-eval))
@(the-eval '(require opencage))

@title{OpenCage Geocoding Client for Racket}
@author{OpenCage SDK Contributors}

@defmodule[opencage]

@section{Overview}
The @racketmodname[opencage] library provides a lightweight interface to the
@hyperlink["https://opencagedata.com/api"]{OpenCage Geocoding API}, supporting
forward and reverse geocoding, basic rate limit tracking, and structured error reporting.

@section{Quick Start}
@codeblock{
 (require opencage)
 (define api-key (or (getenv "OPENCAGE_API_KEY") (error 'demo "set OPENCAGE_API_KEY")))
 (define c (make-opencage-client api-key #:defaults '((language . "en"))))
 (define r (opencage-geocode c "Berlin" #:params '((limit . 1))))
 (hash-ref (oc-response-data r) 'results)
}

@section{Client Construction}
@defproc[(make-opencage-client [api-key string?]
                               [#:defaults defaults (or/c hash? list?) (hash)]
                               [#:auto-throttle? auto-throttle? boolean? #t]
                               [#:extra-headers extra-headers (listof any/c) '()])
         opencage-client?]{
Create a new client. @racket[defaults] supplies query parameters merged into every
request. Parameters may be a hash, alist, or property list. Extra headers (each either a
pair or full header string) are appended; a proper @tt{User-Agent} is supplied automatically.

If @racket[auto-throttle?] is true and the remaining rate limit reaches zero, the client
will sleep until the reset time (capped to 60 seconds per call).
}

@section{Making Requests}
@defproc[(opencage-geocode [client opencage-client?]
                           [query string?]
                           [#:params params (or/c hash? list?) (hash)])
         oc-response?]{Forward geocode the free–form @racket[query].}

@defproc[(opencage-reverse [client opencage-client?]
                           [lat real?]
                           [lon real?]
                           [#:params params (or/c hash? list?) (hash)])
         oc-response?]{Reverse geocode latitude/longitude.
Coordinates are formatted as "lat,lon" and passed as the @tt{q} parameter.}

@section{Responses}
@defstruct*[oc-response ([data hash?]
                         [status-code exact-nonnegative-integer?]
                         [rate-limit-remaining (or/c exact-nonnegative-integer? #f)]
                         [rate-limit-reset (or/c exact-nonnegative-integer? #f)]
                         [raw hash?])]{}
The @racket[data] field is the parsed JSON (converted to Racket hashes with symbol keys).
Rate limit fields come from @tt{X-RateLimit-Remaining} and @tt{X-RateLimit-Reset} headers.
The @racket[raw] field holds auxiliary data including the original headers and body.

Accessor procedures:
@itemlist[
 @item{@racket[oc-response-data]}
 @item{@racket[oc-response-status-code]}
 @item{@racket[oc-response-rate-limit-remaining]}
 @item{@racket[oc-response-rate-limit-reset]}]

@section{Rate Limits}
Convenience accessors:
@defproc[(opencage-client-rate-remaining [c opencage-client?]) (or/c exact-nonnegative-integer? #f)]{}
@defproc[(opencage-client-rate-reset-seconds [c opencage-client?]) (or/c exact-nonnegative-integer? #f)]{}

@section{Errors}
Failures raise @racket[exn:fail:opencage], a subtype of @racket[exn:fail].
@defstruct*[(exn:fail:opencage exn:fail) ([status-code exact-nonnegative-integer?]
                                          [body any/c])]{}
Accessors:
@itemlist[
 @item{@racket[exn:fail:opencage?]}
 @item{@racket[exn:fail:opencage-status-code]}
 @item{@racket[exn:fail:opencage-body]}]

@section{Version}
@defproc[(opencage-version) string?]{Returns the library version string.}

@section{Parameter Shapes}
Parameters supplied via @racket[#:defaults] or @racket[#:params] may be:
@itemlist[
 @item{Hash: @racket[(hash 'limit 1 'language "en")]}
 @item{Alist: @racket['((limit . 1) (language . "en"))]}
 @item{Property list: @racket['(limit 1 language "en")]}]
Boolean values become 1/0 to satisfy API expectations.

@section{Best Practices}
Always cache the client rather than creating one per request; reuse preserves rate
limit state. Respect the provided attribution guidelines when rendering results.

@section{Example Error Handling}
@codeblock{
 (with-handlers ([exn:fail:opencage? (lambda (e)
                                       (printf "Failed (~a): ~a\n"
                                               (exn:fail:opencage-status-code e)
                                               (exn-message e)))])
   (opencage-geocode c "!!bad!!"))
}

@section{License}
MIT.
