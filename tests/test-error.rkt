#lang racket
(require rackunit opencage)

(test-case "version accessor"
  (define v (opencage-version))
  (check-true (string? v))
  (check-not-equal? v ""))

;; Placeholder for future deterministic unit tests (e.g., parameter normalization)
(test-case "normalize params simple"
  (define c (make-opencage-client "KEY" #:defaults '((no_dedupe . #t))))
  (check-true (opencage-client? c)))
