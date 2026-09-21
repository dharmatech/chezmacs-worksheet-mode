(library (worksheet-mode)
  (export init! run! insert-last!)
  (import (chezscheme)
          (worksheet-env)
          (prefix (core kernel) kernel:)
          (prefix (head edit) edit:)
          (prefix (head echo) echo:)
          (prefix (head head) head:)
          (prefix (head keymap) keymap:)
          (prefix (head mode) mode:)
          (prefix (apps eval) eval:)
          (prefix (service doc) doc:)
          (prefix (service log) log:)
          (prefix (sys sys) sys:))

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

  (define (join-printed vals)
    (let loop ([vals vals] [out #f])
      (cond
        [(null? vals) (or out "")]
        [(not out) (loop (cdr vals) (format "~s" (car vals)))]
        [else (loop (cdr vals)
                    (string-append out ", " (format "~s" (car vals))))])))

  (define (void-result? outcome)
    (or (null? outcome)
        (and (null? (cdr outcome))
             (eq? (car outcome) (void)))))

  (define (report-outcome! outcome)
    (let* ([failed? (string? outcome)]
           [void? (and (not failed?) (void-result? outcome))]
           [text (cond
                   [failed? outcome]
                   [void? (format "~s" (void))]
                   [else (join-printed outcome)])]
           [copied? (and (eval:copy-result) (not failed?) (not void?))])
      (when copied? (edit:copy-to-kill-buffer! text))
      (edit:set-message! text)))

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
              vals))))))

  (define (capture-evaluation label thunk)
    (define (evaluate)
      (guard (ex [(head:interrupted? ex) "interrupted"]
                 [else (format "error: ~a" (kernel:condition-text ex))])
        (head:call-with-interrupt
          (lambda ()
            (edit:call-as-one-edit! label thunk)))))
    (let ([lock (make-mutex)]
          [terminal (sys:duplicate-standard-output-port)])
      (define (record! component line)
        (parameterize ([sys:terminal-output-port terminal])
          (with-mutex lock (log:add! component line))))
      (dynamic-wind
        void
        (lambda ()
          (parameterize ([sys:terminal-output-port terminal])
            (sys:call-with-streamed-output
              (lambda (line) (record! 'stdout line))
              (lambda (line) (record! 'stderr line))
              evaluate)))
        (lambda () (close-port terminal)))))

  (define (run!)
    (report-outcome!
      (capture-evaluation "(worksheet-mode:run!)" evaluate-current))
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
                    (capture-evaluation
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
                          outcome)))])
               (report-outcome! outcome)))])))
    (void))

  (define (init!)
    (prepare-library-directories!)
    (let ([scheme (mode:find "scheme")])
      (mode:register! "worksheet" '(".ws" ".mpl") '()
                      (and scheme (mode:styles scheme))
                      (and scheme (mode:render scheme))
                      (and scheme (mode:row-styles scheme)))
      (let ([indent (mode:indenter "scheme")]
            [format (mode:formatter "scheme")])
        (when indent (mode:register-indenter! "worksheet" indent))
        (when format (mode:register-formatter! "worksheet" format))))
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
