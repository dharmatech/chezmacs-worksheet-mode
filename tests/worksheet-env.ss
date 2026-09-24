(import (chezscheme))

(eval '(import (worksheet-env)) (interaction-environment))

(define fails 0)

(define (ok detail)
  (display "  ok ")
  (display detail)
  (newline))

(define (fail detail)
  (set! fails (+ fails 1))
  (display "  FAIL ")
  (display detail)
  (newline))

(define (condition-text c)
  (if (message-condition? c)
      (condition-message c)
      c))

(define (expect-equal expected thunk detail)
  (guard (c [else
             (fail (string-append detail " (raised: "
                                  (call-with-string-output-port
                                    (lambda (p) (display (condition-text c) p)))
                                  ")"))])
    (let ([actual (thunk)])
      (if (equal? expected actual)
          (ok detail)
          (begin
            (fail detail)
            (display "    expected: ")
            (write expected)
            (newline)
            (display "    actual:   ")
            (write actual)
            (newline))))))

(define (expect-raise thunk detail)
  (guard (c [else (ok detail)])
    (thunk)
    (fail (string-append detail " (did not raise)"))))

(define (expect-ok thunk detail)
  (guard (c [else
             (fail (string-append detail " (raised: "
                                  (call-with-string-output-port
                                    (lambda (p) (display (condition-text c) p)))
                                  ")"))])
    (thunk)
    (ok detail)))

(define (heading title)
  (newline)
  (display title)
  (newline))

;; 1. Default (rnrs) environment
(heading "1. default (rnrs) environment")
(let ([env (make-worksheet-environment default-import-specs)])
  (expect-equal 3 (lambda () (eval '(+ 1 2) env)) "(eval '(+ 1 2) env) => 3")
  (expect-raise (lambda () (eval 'x env)) "(eval 'x env) raises")
  (expect-raise (lambda () (eval 'vars env)) "(eval 'vars env) raises")
  (expect-raise (lambda () (eval 'alge env)) "(eval 'alge env) raises"))

;; 2. MPL goldens, then interaction-environment still Chez +
(heading "2. MPL goldens")
(define mpl-specs '((mpl rnrs-sans) (mpl all)))
(define mpl-env (make-worksheet-environment mpl-specs))
(eval '(vars a b c d x y z pi t) mpl-env)
(expect-equal '(* 2 x)
              (lambda () (eval '(+ x x) mpl-env))
              "(+ x x) => (* 2 x)")
(expect-equal '(* (^ x 2) y)
              (lambda () (eval '(* x y x) mpl-env))
              "(* x y x) => (* (^ x 2) y)")
(expect-equal '(+ 5 (* 2 x) y (* 2 z))
              (lambda () (eval '(+ x y x z 5 z) mpl-env))
              "(+ x y x z 5 z)")
(expect-equal '(+ 1 (* 2 x) (^ x 2))
              (lambda () (eval '(algebraic-expand (alge "(x+1)^2")) mpl-env))
              "(algebraic-expand (alge \"(x+1)^2\"))")
(expect-equal '(+ 24 (* 26 x) (* 9 (^ x 2)) (^ x 3))
              (lambda ()
                (eval '(algebraic-expand (alge "(x+2)*(x+3)*(x+4)")) mpl-env))
              "(algebraic-expand (alge \"(x+2)*(x+3)*(x+4)\"))")
(expect-equal '(cos x)
              (lambda () (eval '(derivative (alge "sin(x)") x) mpl-env))
              "(derivative (alge \"sin(x)\") x)")
(expect-equal '(+ (* 6 x) (* 3 (^ x 2)))
              (lambda ()
                (eval '(derivative (alge "x^3 + 3*x^2 + 5") x) mpl-env))
              "(derivative (alge \"x^3 + 3*x^2 + 5\") x)")
(let ([rnrs-env (make-worksheet-environment default-import-specs)])
  (expect-equal 3
                (lambda () (eval '(+ 1 2) rnrs-env))
                "(+ 1 2) in default (rnrs) worksheet env"))
(expect-equal 3
              (lambda () (eval '(+ 1 2) (interaction-environment)))
              "(+ 1 2) in the interaction environment after private envs")

;; 3. vars is worksheet code, not construction
(heading "3. no auto-vars")
(expect-equal '(* 2 x)
              (lambda () (eval '(+ x x) mpl-env))
              "(+ x x) after vars, no mpl: prefix")
(let ([fresh (make-worksheet-environment mpl-specs)])
  (expect-raise (lambda () (eval 'x fresh))
                "fresh MPL env without vars: x unbound"))

;; 4. environments do not share definitions
(heading "4. isolated environments")
(let ([e1 (make-worksheet-environment default-import-specs)]
      [e2 (make-worksheet-environment default-import-specs)])
  (eval '(define k 1) e1)
  (expect-raise (lambda () (eval 'k e2))
                "(eval 'k e2) raises after (define k 1) in e1"))

;; 5. parse-worksheet with no import
(heading "5. parse-worksheet default")
(let-values ([(specs remaining) (parse-worksheet "(+ 1 2)")])
  (expect-equal '((rnrs)) (lambda () specs)
                "parse-worksheet \"(+ 1 2)\" specs")
  (expect-equal '((+ 1 2)) (lambda () remaining)
                "parse-worksheet \"(+ 1 2)\" remaining"))

;; 6. parse-worksheet leading import replaces default
(heading "6. parse-worksheet leading import")
(define mpl-header
  "(import (mpl rnrs-sans)\n        (mpl all))\n\n(vars x y)\n\n(+ x x)\n")
(let-values ([(specs remaining) (parse-worksheet mpl-header)])
  (expect-equal '((mpl rnrs-sans) (mpl all))
                (lambda () specs)
                "leading import specs, not concatenated with default")
  (expect-equal '((vars x y) (+ x x))
                (lambda () remaining)
                "remaining forms without the import"))

;; 7. eval-program drops leading import (does not eval it)
(heading "7. eval-program leading import")
(let ([env (make-worksheet-environment
             (let-values ([(specs _) (parse-worksheet mpl-header)])
               specs))])
  (expect-equal '(* 2 x)
                (lambda () (eval-program mpl-header env))
                "eval-program import + vars + (+ x x) => (* 2 x)"))

;; 8. define persists
(heading "8. define persists")
(let ([env (make-worksheet-environment default-import-specs)])
  (eval-forms '((define k 1) k) env)
  (expect-equal 1 (lambda () (eval 'k env)) "define then k => 1"))

;; 9. eval of import in the copy raises
(heading "9. eval import in copy raises")
(let ([env (make-worksheet-environment default-import-specs)])
  (expect-raise (lambda () (eval '(import (rnrs)) env))
                "(eval '(import (rnrs)) env) raises"))

;; 10. clash table
(heading "10. clash table")
(expect-raise
  (lambda () (make-worksheet-environment '((rnrs) (mpl all))))
  "'((rnrs) (mpl all)) raises")
(expect-ok
  (lambda () (make-worksheet-environment '((mpl rnrs-sans) (mpl all))))
  "'((mpl rnrs-sans) (mpl all)) succeeds")
(expect-ok
  (lambda () (make-worksheet-environment '((rnrs) (rnrs))))
  "'((rnrs) (rnrs)) succeeds")
(expect-ok
  (lambda () (make-worksheet-environment '((rnrs) (prefix (mpl all) mpl:))))
  "'((rnrs) (prefix (mpl all) mpl:)) succeeds")
(expect-ok
  (lambda () (make-worksheet-environment '((chezscheme))))
  "'((chezscheme)) succeeds")
(expect-raise
  (lambda () (make-worksheet-environment '((rnrs) (chezscheme))))
  "'((rnrs) (chezscheme)) raises")

;; 11. two leading import forms concatenate
(heading "11. two leading import forms")
(define two-imports
  "(import (mpl rnrs-sans))\n(import (mpl all))\n(vars x y)\n(+ x x)\n")
(let-values ([(specs remaining) (parse-worksheet two-imports)])
  (expect-equal '((mpl rnrs-sans) (mpl all))
                (lambda () specs)
                "two leading imports concatenate, not plus default")
  (expect-equal '((vars x y) (+ x x))
                (lambda () remaining)
                "remaining without either import")
  (let ([env (make-worksheet-environment specs)])
    (expect-equal '(* 2 x)
                  (lambda () (eval-program two-imports env))
                  "eval-program two imports + vars + (+ x x)")))

;; 12. non-leading import is an error
(heading "12. non-leading import")
(let ([env (make-worksheet-environment default-import-specs)])
  (expect-raise
    (lambda ()
      (eval-program "(define k 1)\n(import (rnrs))\n" env))
    "eval-program of define then (import (rnrs)) raises"))

(expect-ok
  (lambda () (make-worksheet-environment '()))
  "extra: empty spec list succeeds")

(newline)
(if (zero? fails)
    (begin (display "All checks passed.\n") (exit 0))
    (begin
      (display fails)
      (display " check(s) failed.\n")
      (exit 1)))
