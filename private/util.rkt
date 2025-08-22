#lang racket
(require racket/match racket/string racket/list)
(provide kvs->hash normalize-params bool->01)

(define (kvs->hash v)
  (cond
    [(hash? v) (for/hash ([(k val) (in-hash v)]) (values k val))]
    ;; alist
    [(and (list? v) (andmap pair? v)) (for/hash ([p (in-list v)]) (values (car p) (cdr p)))]
    ;; plist
    [(and (list? v) (even? (length v)))
     (let loop ([lst v] [acc (hash)])
       (if (null? lst) acc (loop (cddr lst) (hash-set acc (car lst) (cadr lst)))))]
    [else (error 'kvs->hash (format "Unsupported params shape: ~a" v))]))

(define (bool->01 v)
  (cond [(eq? v #t) 1]
        [(eq? v #f) 0]
        [else v]))

(define (normalize-params h)
  (for/hash ([(k v) (in-hash h)])
    (values (if (symbol? k) k (string->symbol (~a k))) (bool->01 v))))
