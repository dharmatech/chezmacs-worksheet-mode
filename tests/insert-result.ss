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
                                    (lambda (p)
                                      (display (condition-text c) p)))
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

(define (expect-true thunk detail)
  (expect-equal #t (lambda () (and (thunk) #t)) detail))

(define (heading title)
  (newline)
  (display title)
  (newline))

(define (string-find text needle)
  (let ([n (string-length text)] [m (string-length needle)])
    (let search ([i 0])
      (cond
        [(> (+ i m) n) #f]
        [(string=? (substring text i (+ i m)) needle) i]
        [else (search (+ i 1))]))))

(define (selection text limit)
  (call-with-values
    (lambda () (last-complete-datum-at text limit))
    list))

(define (apply-plan text start end replacement)
  (string-append (substring text 0 start)
                 replacement
                 (substring text end (string-length text))))

(define (check-splice text form-end comment expected detail)
  (guard (c [else
             (fail (string-append detail " (raised: "
                                  (call-with-string-output-port
                                    (lambda (p)
                                      (display (condition-text c) p)))
                                  ")"))])
    (let-values ([(new-text start end replacement)
                  (splice-result-comment text form-end comment)])
      (if (and (string=? new-text expected)
               (string=? (apply-plan text start end replacement) new-text))
          (ok detail)
          (begin
            (fail detail)
            (display "    expected text: ") (write expected) (newline)
            (display "    actual text:   ") (write new-text) (newline)
            (display "    plan:          ")
            (write (list start end replacement))
            (newline))))))

;; A writer with literal line breaks makes the result-normalization policy
;; observable; a Scheme string would print those characters as escapes.
(define-record-type line-breaking-value)
(define line-breaking-value-writer
  (record-writer
    (record-type-descriptor line-breaking-value)
    (lambda (record port write-value)
      (display "a\r\n\nb" port))))

(heading "1. positions and character indexes")
(define position-text "ab\nλz\nq")
(for-each
  (lambda (position)
    (expect-equal
      position
      (lambda ()
        (index->position position-text
                         (position->index position-text position)))
      (format "round trip ~s" position)))
  '((0 . 0) (0 . 2) (2 . 1) (1 . 1)))
(expect-equal 4
              (lambda () (position->index position-text '(1 . 1)))
              "non-ASCII columns and indexes count characters")

(heading "2. last complete datum")
(define two-forms "(+ 1 2)\n(* 2 3)\n")
(define first-end (string-length "(+ 1 2)"))
(expect-equal (list #t '(+ 1 2) first-end)
              (lambda () (selection two-forms first-end))
              "form ending exactly at point is selected")
(expect-equal (list #t '(+ 1 2) first-end)
              (lambda () (selection two-forms (+ first-end 4)))
              "point in a later list selects the preceding form")

(define identifier-text "alpha\nlongidentifier\n")
(expect-equal (list #t 'alpha (string-length "alpha"))
              (lambda ()
                (selection identifier-text
                           (+ (string-length "alpha\nlong") 0)))
              "point in a later identifier does not select a prefix symbol")
(expect-equal '(#f #f #f)
              (lambda () (selection "(+ 1 2)" 2))
              "before any complete datum reports none")

(define comment-text "(+ 1 2) ; a comment\n")
(expect-equal (list #t '(+ 1 2) first-end)
              (lambda () (selection comment-text (+ first-end 5)))
              "point in a line comment selects the preceding datum")
(expect-equal (list #t '(+ 1 2) first-end)
              (lambda ()
                (selection "(+ 1 2)\n(\"unterminated"
                           (string-length "(+ 1 2)\n(\"unterminated")))
              "reader failure in a later datum preserves the preceding datum")

(define two-imports
  "(import (mpl rnrs-sans))\n(import (mpl all))\n(vars x)\n(+ x x)\n")
(define plus-offset (string-find two-imports "(+ x x)"))
(define plus-end (+ plus-offset (string-length "(+ x x)")))
(expect-equal (list #t '(+ x x) plus-end)
              (lambda () (selection two-imports plus-end))
              "two imports precede, but do not displace, the selected form")

(heading "3. result rendering")
(expect-equal "; => (* 2 x)"
              (lambda () (render-result-comment (list '(* 2 x))))
              "symbolic result renders exactly")
(expect-equal "; => 1, 2"
              (lambda () (render-result-comment (list 1 2)))
              "multiple values use comma-space")
(expect-equal "; => #f"
              (lambda () (render-result-comment (list #f)))
              "a #f value is not confused with no result")
(expect-equal #f
              (lambda () (render-result-comment '()))
              "zero values do not render")
(expect-equal #f
              (lambda () (render-result-comment (list (void))))
              "one void value does not render")
(expect-equal "; => a b"
              (lambda ()
                (render-result-comment (list (make-line-breaking-value))))
              "a maximal CR/LF run becomes one space")

(heading "4. result splicing")
(define result-a "; => (* 2 x)")
(define result-b "; => (* 3 x)")
(define source-form "(+ x x)")
(define source-end (string-length source-form))
(define inserted
  (string-append source-form "\n" result-a "\n(next)\n"))
(check-splice (string-append source-form "\n(next)\n")
              source-end result-a inserted
              "nonblank next line is pushed down by one local insertion")
(check-splice inserted source-end result-b
              (string-append source-form "\n" result-b "\n(next)\n")
              "re-splicing replaces instead of stacking")
(check-splice (string-append source-form "\n \t; => stale\n(next)\n")
              source-end result-a inserted
              "indented old result is recognized and canonicalized")
(check-splice (string-append source-form "\n \t \n(next)\n")
              source-end result-a inserted
              "whitespace-only next line is reused")
(check-splice source-form source-end result-a
              (string-append source-form "\n" result-a)
              "no-final-newline style is preserved")
(check-splice (string-append source-form "\n") source-end result-a
              (string-append source-form "\n" result-a "\n")
              "terminal-newline style is preserved")

(heading "5. void and error outcomes do not write")
(define existing-result
  (string-append "(define k 1)\n; => keep me\n"))
(define default-env (make-worksheet-environment default-import-specs))
(define define-outcome
  (call-with-values
    (lambda () (eval '(define k 1) default-env))
    list))
(expect-equal #f
              (lambda () (render-result-comment define-outcome))
              "define produces the single-void no-result outcome")
(expect-equal (list existing-result #f #f #f)
              (lambda ()
                (call-with-values
                  (lambda ()
                    (splice-result-comment
                      existing-result
                      (string-length "(define k 1)")
                      (render-result-comment define-outcome)))
                  list))
              "void leaves an existing good result untouched")

(define error-outcome
  (guard (c [else (format "error: ~a" (condition-text c))])
    (call-with-values
      (lambda () (eval 'missing-name default-env))
      list)))
(expect-true (lambda ()
               (and (string? error-outcome)
                    (>= (string-length error-outcome) 7)
                    (string=? (substring error-outcome 0 7) "error: ")))
             "evaluation failure has the mode's error-string shape")
(expect-equal #f
              (lambda () (render-result-comment error-outcome))
              "error outcome does not render")
(expect-equal (list existing-result #f #f #f)
              (lambda ()
                (call-with-values
                  (lambda ()
                    (splice-result-comment
                      existing-result
                      (string-length "(define k 1)")
                      (render-result-comment error-outcome)))
                  list))
              "error leaves an existing good result untouched")

(heading "6. MPL golden")
(define mpl-text
  (call-with-input-file "examples/mpl.ws" get-string-all))
(let-values ([(specs _) (parse-worksheet mpl-text)])
  (let* ([env (make-worksheet-environment specs)]
         [vars-source "(vars a b c d x y z pi t)"]
         [vars-start (string-find mpl-text vars-source)]
         [vars-end (+ vars-start (string-length vars-source))]
         [plus-start (string-find mpl-text "(+ x x)")]
         [plus-end (+ plus-start (string-length "(+ x x)"))])
    (let-values ([(vars-found? vars-datum vars-source-end)
                  (last-complete-datum-at mpl-text vars-end)])
      (expect-equal (list #t '(vars a b c d x y z pi t) vars-end)
                    (lambda ()
                      (list vars-found? vars-datum vars-source-end))
                    "MPL vars form is selected at its exact source end")
      (eval vars-datum env))
    (let-values ([(found? datum source-end)
                  (last-complete-datum-at mpl-text plus-end)])
      (expect-equal (list #t '(+ x x) plus-end)
                    (lambda () (list found? datum source-end))
                    "MPL (+ x x) is selected at its exact source end")
      (let* ([outcome (call-with-values (lambda () (eval datum env)) list)]
             [comment (render-result-comment outcome)]
             [next-line-start (+ (string-find mpl-text "(* x y x)") 0)]
             [expected
              (string-append (substring mpl-text 0 next-line-start)
                             "; => (* 2 x)\n"
                             (substring mpl-text next-line-start
                                        (string-length mpl-text)))])
        (expect-equal '((* 2 x))
                      (lambda () outcome)
                      "MPL selected datum evaluates exactly to (* 2 x)")
        (expect-equal "; => (* 2 x)"
                      (lambda () comment)
                      "MPL value renders to the exact result comment")
        (let-values ([(spliced start end replacement)
                      (splice-result-comment mpl-text source-end comment)])
          (expect-equal expected
                        (lambda () spliced)
                        "MPL comment is spliced at the following-line slot")
          (expect-equal expected
                        (lambda ()
                          (apply-plan mpl-text start end replacement))
                        "MPL local edit plan reproduces the full splice"))))))

(newline)
(if (zero? fails)
    (begin (display "All checks passed.\n") (exit 0))
    (begin
      (display fails)
      (display " check(s) failed.\n")
      (exit 1)))
