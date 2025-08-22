OpenCage Geocoding SDK for Racket
=================================

Lightweight Racket client for the [OpenCage Geocoding API](https://opencagedata.com/api).

Status: initial alpha (unpublished package). Feedback welcome.

## Features

- Forward geocoding (`opencage-geocode`)
- Reverse geocoding (`opencage-reverse`)
- Simple client object with default params
- Optional params via keywords (as a hash, alist, or plist)
- Rate‑limit header exposure (remaining & reset epoch)
- Structured error with response body & status code
- Skips network tests automatically when no API key present
- Custom extra headers & proper User-Agent per SDK guidelines
- Library version accessor (`opencage-version`)

## Install (local checkout)

Clone into a directory on your Racket `PLTCOLLECTS` path or use `raco pkg install` pointing to the folder:

```sh
raco pkg install --name opencage ./racket
```

## Usage

```racket
#lang racket
(require opencage)

;; API key must be provided via environment:
;;   export OPENCAGE_API_KEY=YOUR_REAL_KEY
;; Get a key: https://opencagedata.com/
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
q (handled internally), limit, language, countrycode, bounds, proximity,
no_annotations, no_dedupe, abbrv, roadinfo, min_confidence, pretty
```

Boolean values are converted to `1` / `0` automatically.

### Error Handling

Network & API errors raise `exn:fail:opencage`:

```racket
(with-handlers ([exn:fail:opencage? (λ(e) (printf "Error ~a: ~a\n"
                                                 (exn:fail:opencage-status-code e)
                                                 (exn-message e)))])
  (opencage-geocode c "NonexistentPlace123456"))
```

### Rate Limits

Expose headers: `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

### Tests

```sh
raco test opencage/tests
```
If `OPENCAGE_API_KEY` is absent, network tests are skipped.

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

## Roadmap

- Add batching helpers
- Add structured types for components
- Add automatic retry on 502/503 with backoff
- Publish to Racket package catalog
- Add Scribble reference docs

## CI & Releases

Continuous integration: GitHub Actions workflow (`.github/workflows/ci.yml`) runs tests across several Racket versions. Network tests are skipped unless `OPENCAGE_API_KEY` is supplied as a repository secret.

Release helper script: `scripts/publish.sh` verifies version consistency (between `info.rkt` and `client.rkt`), creates a version tag `vX.Y.Z`, and pushes it.

First time publishing:
1. Ensure version updated in `info.rkt` and `client.rkt` (`OPCAGE-VERSION`).
2. Run `scripts/publish.sh`.
3. Submit the repo URL to https://pkgs.racket-lang.org/ (only once).

After initial submission, pushing a new tag picked up by the package index.

PRs & issues welcome.
