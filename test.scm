; 普通の計算
(+ 1 1)
(- 3 1)

; ラムダ抽象とdefine
(define inc
  (lambda (x) (+ x 1)))

(define (dec x) (- x 1))

; cond
(define (fee age)
  (cond
   ((or (<= age 3) (>= age 65)) 0)
   ((<= 4 age 6) 50)
   ((<= 7 age 12) 100)
   ((<= 13 age 15) 150)
   ((<= 16 age 18) 180)
   (else 200)))

; let系
(let ((x 1) (y 2)) (+ x y))

(let loop ((x 10)) (if (= x 0) 1 (* (loop (- x 1)) x)))

(let* ((x 1) (y (+ x 2))) (+ x y))

(define (fact-letrec n)
  (letrec ((iter (lambda (n1 p)
                   (if (= n1 1)
                     p
                     (let ((m (- n1 1)))
                       (iter m (* p m)))))))
    (iter n n)))

; begin
(begin
  (display (+ 1 1))
  (display (- 1 1))
  (display (* 4 2)))

; do
(do
  ((a 1 (+ a b))
   (b 1 (+ b a)))
  ((> a 100) a)
  (display a b))

; cosを計算
(reflection-method (reflection-object "Math") "cos" '(1))

; ホスト言語のevalを呼ぶeval
(define (eval code)
  (haxeobject->val
    (reflection-method 
      (reflection-object "src.Main") "evaluate" (list code))))

(define (let*-expander vars body)
(if (null? vars)
 (cons 'begin body)
 (list 'let (list (car vars)) (let*-expander (cdr vars) body))))

(define-macro (let** vars . body)
(let*-expander vars body))
