OpenCage Geocoding SDK for Racket
=================================

Lightweight Racket client for the [OpenCage Geocoding API](https://opencagedata.com/api).

| Service | Status |
|---------|--------|
| Package | [opencage](https://pkgd.racket-lang.org/pkgn/package/opencage) |
| CI      | [![CI](https://github.com/geonot/opencage-racket/actions/workflows/ci.yml/badge.svg)](https://github.com/geonot/opencage-racket/actions/workflows/ci.yml) |

## Features

- Forward geocoding (`opencage-geocode`)
- Reverse geocoding (`opencage-reverse`)
- Simple client object with default params
- Optional params via keywords (as a hash, alist, or plist)

## Install / Manage

Catalog install (preferred):

```sh
raco pkg install opencage
```

Update to latest (catalog checksums drive updates, not just version field):

```sh
raco pkg update opencage
```

Remove:

```sh
raco pkg remove opencage
```

Local development (link the working directory so edits are live):

```sh
git clone https://github.com/geonot/opencage-racket.git
cd opencage-racket/racket
raco pkg install --link
```

## Usage


```racket
#lang racket
(require opencage)

(define api-key
  (or (getenv "OPENCAGE_API_KEY")
      (error 'opencage "OPENCAGE_API_KEY not set")))

(define c
  (make-opencage-client api-key
                        #:defaults '((language . "en")
                                     (no_annotations . #t))
                        ;; You can supply arbitrary additional headers if needed:
                        #:extra-headers '(("X-My-App" . "demo"))))

;; Forward geocode
(define resp (opencage-geocode c "Berlin" #:params '((limit . 1))))
(printf "First result formatted: ~a\n"
        (hash-ref (first (hash-ref (oc-response-data resp) 'results)) 'formatted))

;; Reverse geocode (lat lon)
(define rev (opencage-reverse c 52.5200 13.4050))
(printf "Reverse components keys: ~a\n"
        (hash-keys (hash-ref (first (hash-ref (oc-response-data rev) 'results)) 'components)))

;; Rate limit info
(printf "Remaining: ~a Reset(Epoch): ~a\n"
        (oc-response-rate-limit-remaining resp)
        (oc-response-rate-limit-reset resp))
```

### Optional Parameters

Pass via `#:params` as any of:

1. Hash `(hash 'limit 1 'language "fr")`
2. Alist `'((limit . 1) (language . "fr"))`
3. Property list `'(limit 1 language "fr")`

Common params (see full API docs):

```
q, limit, language, countrycode, bounds, proximity,
no_annotations, no_dedupe, abbrv, roadinfo, min_confidence, pretty
```

### Error Handling

Network & API errors raise `exn:fail:opencage`:

```racket
(with-handlers ([exn:fail:opencage?
                                                                 (λ (e)
                                                                         (printf "Error ~a: ~a\n"
                                                                                                         (exn:fail:opencage-status-code e)
                                                                                                         (exn-message e)))])
        (opencage-geocode c "NonexistentPlace123456"))
```

### Tests

```sh
raco test opencage/tests
```

## API Surface

Exports (from `(require opencage)`):

```
make-opencage-client
opencage-client? opencage-geocode opencage-reverse
oc-response? oc-response-data oc-response-status-code
oc-response-rate-limit-remaining oc-response-rate-limit-reset
exn:fail:opencage? exn:fail:opencage-status-code exn:fail:opencage-body
opencage-version
```

## License

MIT – see `LICENSE`.

## Contributing

PRs & issues welcome.
