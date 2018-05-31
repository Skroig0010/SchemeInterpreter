(begin (define (let*-expander vars body)
(if (null? vars)
 (cons 'begin body)
 (list 'let (list (car vars)) (let*-expander (cdr vars) body))))

(define-macro (let* vars . body)
(let*-expander vars body)))
