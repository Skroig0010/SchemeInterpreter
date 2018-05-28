(begin 
  (define cadr (lambda (x) (car (cdr x))))
  (define cdar (lambda (x) (cdr (car x))))
  (define caar (lambda (x) (car (car x))))
  (define cddr (lambda (x) (cdr (cdr x))))

  (define (get-firsts . lists)
    (if (null? (cdr lists))
      (cons (caar lists) '())
      (cons (caar lists) (get-firsts (cadr lists)))))

  (define (get-nexts . lists)
    (if (null? (cdr lists))
      (cons (cdar lists) '())
      (cons (cdar lists) (get-nexts (cadr lists)))))

  (define (map procedure . lists)
    (if (null? (cdr lists))
      (cons (apply procedure (get-firsts lists)) '())
      (cons (apply procedure (get-firsts lists)) (get-nexts lists))))

  (define-macro (my-let binds . body)
                (lambda (binds . body)
                  '((lambda (map car binds) body) (map cadr body)))) )
