(library (worksheet-mode)
  (export init! run! insert-last!)
  (import (chezscheme)
          (worksheet-env)
          (prefix (core kernel) kernel:)
          (prefix (head edit) edit:)
          (prefix (head head) head:)
          (prefix (head keymap) keymap:)
          (prefix (head mode) mode:)
          (prefix (apps eval) eval:)
          (prefix (service doc) doc:))

  ;; Live environments cannot live in buffer facts: facts may be serialized.
  (define environments
    (unbox (kernel:persistent-cell 'worksheet-mode-environments
             (lambda () (make-weak-eq-hashtable)))))

  (define (environment-for buffer specs)
    (let ([old (hashtable-ref environments buffer #f)])
      (if (and old (equal? (car old) specs))
          (cdr old)
          (let ([env (make-worksheet-environment specs)])
            (hashtable-set! environments buffer (cons specs env))
            env))))

  (define (evaluate-current)
    (let ([buffer (head:current-buffer)])
      (let ([text (edit:buffer-text buffer)]
            [span (edit:region-text (edit:current-region))]
            [region? (and (head:mark) #t)])
        (let-values ([(specs _) (parse-worksheet text)])
          (let ([env (environment-for buffer specs)])
            (let-values ([vals
                          (if region?
                              (eval-forms (read-forms span) env)
                              (eval-program text env))])
              (apply values vals)))))))

  (define (run!)
    (eval:report!
      (eval:call-with-evaluation! "(worksheet-mode:run!)" evaluate-current))
    (void))

  (define (insert-last!)
    (let* ([buffer (head:current-buffer)]
           [text (edit:buffer-text buffer)]
           [limit (position->index text (head:point))])
      (let-values ([(found? datum datum-end)
                    (last-complete-datum-at text limit)])
        (cond
          [(not found?)
           (edit:set-message! "No complete form before point")]
          [(and (pair? datum) (eq? (car datum) 'import))
           (edit:set-message! "error: import is worksheet environment syntax")]
          [else
           (let-values ([(specs _) (parse-worksheet text)])
             (let ([outcome
                    (eval:call-with-evaluation!
                      "(worksheet-mode:insert-last!)"
                      (lambda ()
                        (let* ([env (environment-for buffer specs)]
                               [outcome
                                (call-with-values
                                  (lambda () (eval datum env))
                                  list)]
                               [comment (render-result-comment outcome)])
                          (when comment
                            (let-values ([(_ edit-start edit-end replacement)
                                          (splice-result-comment
                                            text datum-end comment)])
                              (head:with-buffer buffer
                                (edit:replace-region-text!
                                  (index->position text edit-start)
                                  (index->position text edit-end)
                                  replacement)
                                (edit:set-point-without-scroll!
                                  (index->position text datum-end)))))
                          (apply values outcome))))])
               (eval:report! outcome)))])))
    (void))

  (define (init!)
    (mode:derive! "worksheet" "scheme" '(".ws" ".mpl"))
    (keymap:bind-default! 'worksheet "C-x C-e" run!)
    (keymap:bind-default! 'worksheet "C-c C-c" insert-last!)
    (doc:register!
      '(((worksheet-mode:run!)
         (("procedure" . "(worksheet-mode:run!)")) "void"
         ("(worksheet-mode)") run! "Worksheets" #f
         "Evaluate the selected region, else the whole current buffer, in that buffer's worksheet environment.")
        ((worksheet-mode:insert-last!)
         (("procedure" . "(worksheet-mode:insert-last!)")) "void"
         ("(worksheet-mode)") insert-last! "Worksheets" #f
         "Evaluate the last complete form at or before point in the buffer's worksheet environment, ignoring the mark; for a non-void success, insert or replace a following ; => comment, while errors and void results stay out of the file."))))

)
