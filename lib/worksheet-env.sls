(library (worksheet-env)
  (export
    src-root
    object-directory
    prepare-library-directories!
    default-import-specs
    read-forms
    parse-worksheet
    make-worksheet-environment
    position->index
    index->position
    last-complete-datum-at
    render-result-comment
    splice-result-comment
    eval-forms
    eval-program)
  (import (chezscheme))

  (define src-root "/home/dharmatech/src")

  (define object-directory
    "/home/dharmatech/src/chezmacs-worksheet-mode/eo")

  (define lib-root
    "/home/dharmatech/src/chezmacs-worksheet-mode/lib")

  (define default-import-specs '((rnrs)))

  (define (prepare-library-directories!)
    (compile-imported-libraries #t)
    (unless (file-directory? object-directory)
      (mkdir object-directory))
    (unless (assoc src-root (library-directories))
      (library-directories
        (cons (cons src-root object-directory)
              (library-directories))))
    (unless (assoc lib-root (library-directories))
      (library-directories
        (cons (cons lib-root object-directory)
              (library-directories)))))

  (define (read-forms str)
    (let ([in (open-input-string str)])
      (let loop ([acc '()])
        (let ([form (read in)])
          (if (eof-object? form)
              (reverse acc)
              (loop (cons form acc)))))))

  (define (leading-import? form)
    (and (pair? form) (eq? (car form) 'import)))

  (define (parse-worksheet str)
    (let ([forms (read-forms str)])
      (let loop ([forms forms] [specs '()] [saw-import? #f])
        (if (and (pair? forms) (leading-import? (car forms)))
            (loop (cdr forms)
                  (append specs (cdar forms))
                  #t)
            (values (if saw-import? specs default-import-specs)
                    forms)))))

  ;; Successful eval of a name, including a value of #f. A raised
  ;; eval means the name is not a variable in this spec (syntax-only
  ;; or unbound).
  (define (eval-variable name env)
    (guard (c [else (values #f #f)])
      (values #t (eval name env))))

  (define (all-eq? vals)
    (or (null? vals)
        (null? (cdr vals))
        (and (eq? (car vals) (cadr vals))
             (all-eq? (cdr vals)))))

  (define (union-symbols lists)
    (let ([ht (make-eq-hashtable)])
      (for-each
        (lambda (ls)
          (for-each (lambda (s) (hashtable-set! ht s #t)) ls))
        lists)
      (vector->list (hashtable-keys ht))))

  (define (assert-no-variable-clashes! import-specs)
    (let* ([envs (map (lambda (spec) (environment spec)) import-specs)]
           [names (union-symbols (map environment-symbols envs))])
      (for-each
        (lambda (name)
          (let ([vals (let collect ([envs envs] [acc '()])
                        (if (null? envs)
                            (reverse acc)
                            (let-values ([(ok? val)
                                          (eval-variable name (car envs))])
                              (collect (cdr envs)
                                       (if ok? (cons val acc) acc)))))])
            (unless (or (null? vals)
                        (null? (cdr vals))
                        (all-eq? vals))
              (error 'make-worksheet-environment
                     "conflicting exported variables"
                     name))))
        names)))

  (define (make-worksheet-environment import-specs)
    (prepare-library-directories!)
    (assert-no-variable-clashes! import-specs)
    (copy-environment (apply environment import-specs) #t))

  (define (position->index text position)
    (unless (and (pair? position)
                 (integer? (car position))
                 (exact? (car position))
                 (>= (car position) 0)
                 (integer? (cdr position))
                 (exact? (cdr position))
                 (>= (cdr position) 0))
      (error 'position->index "invalid position" position))
    (let ([wanted-row (car position)]
          [wanted-col (cdr position)]
          [n (string-length text)])
      (let rows ([row 0] [start 0])
        (let find-end ([end start])
          (cond
            [(or (= end n) (char=? (string-ref text end) #\newline))
             (cond
               [(= row wanted-row)
                (if (<= wanted-col (- end start))
                    (+ start wanted-col)
                    (error 'position->index "column out of range" position))]
               [(or (= end n) (= (+ end 1) n))
                (error 'position->index "row out of range" position)]
               [else (rows (+ row 1) (+ end 1))])]
            [else (find-end (+ end 1))])))))

  (define (index->position text index)
    (let ([n (string-length text)])
      (unless (and (integer? index) (exact? index)
                   (>= index 0) (<= index n))
        (error 'index->position "index out of range" index))
      (let loop ([i 0] [row 0] [col 0])
        (if (= i index)
            (cons row col)
            (if (char=? (string-ref text i) #\newline)
                (loop (+ i 1) (+ row 1) 0)
                (loop (+ i 1) row (+ col 1)))))))

  (define (last-complete-datum-at text limit)
    (let ([n (string-length text)])
      (unless (and (integer? limit) (exact? limit)
                   (>= limit 0) (<= limit n))
        (error 'last-complete-datum-at "limit out of range" limit))
      (let ([in (open-input-string text)])
        (let loop ([found? #f] [saved-datum #f] [saved-end #f])
          (guard (ex [else (values found? saved-datum saved-end)])
            (let ([datum (read in)])
              (if (eof-object? datum)
                  (values found? saved-datum saved-end)
                  (let ([end (port-position in)])
                    (if (> end limit)
                        (values found? saved-datum saved-end)
                        (loop #t datum end))))))))))

  (define (join-printed-values vals)
    (call-with-string-output-port
      (lambda (out)
        (let loop ([vals vals] [first? #t])
          (unless (null? vals)
            (unless first? (display ", " out))
            (display (format "~s" (car vals)) out)
            (loop (cdr vals) #f))))))

  (define (collapse-line-breaks text)
    (call-with-string-output-port
      (lambda (out)
        (let loop ([i 0] [in-break? #f])
          (unless (= i (string-length text))
            (let* ([ch (string-ref text i)]
                   [break? (or (char=? ch #\return)
                               (char=? ch #\newline))])
              (cond
                [(and break? (not in-break?)) (write-char #\space out)]
                [(not break?) (write-char ch out)])
              (loop (+ i 1) break?)))))))

  (define (render-result-comment outcome)
    (cond
      [(string? outcome) #f]
      [(null? outcome) #f]
      [(and (null? (cdr outcome)) (eq? (car outcome) (void))) #f]
      [else
       (string-append "; => "
                      (collapse-line-breaks
                        (join-printed-values outcome)))]))

  (define (line-end-index text start)
    (let ([n (string-length text)])
      (let loop ([i start])
        (if (or (= i n) (char=? (string-ref text i) #\newline))
            i
            (loop (+ i 1))))))

  (define (whitespace-only? text start end)
    (let loop ([i start])
      (or (= i end)
          (and (char-whitespace? (string-ref text i))
               (loop (+ i 1))))))

  (define (result-line? text start end)
    (let skip ([i start])
      (cond
        [(and (< i end) (char-whitespace? (string-ref text i)))
         (skip (+ i 1))]
        [else
         (and (<= (+ i 4) end)
              (char=? (string-ref text i) #\;)
              (char=? (string-ref text (+ i 1)) #\space)
              (char=? (string-ref text (+ i 2)) #\=)
              (char=? (string-ref text (+ i 3)) #\>))])))

  (define (splice-result-comment text form-end comment)
    (if (not comment)
        (values text #f #f #f)
        (let ([n (string-length text)])
          (define (finish start end replacement)
            (values
              (string-append (substring text 0 start)
                             replacement
                             (substring text end n))
              start end replacement))
          (unless (and (integer? form-end) (exact? form-end)
                       (> form-end 0) (<= form-end n))
            (error 'splice-result-comment "form end out of range" form-end))
          (let ([form-line-end (line-end-index text form-end)])
            (if (and (< form-line-end n) (< (+ form-line-end 1) n))
                (let* ([next-start (+ form-line-end 1)]
                       [next-end (line-end-index text next-start)])
                  (cond
                    [(or (result-line? text next-start next-end)
                         (whitespace-only? text next-start next-end))
                     (finish next-start next-end comment)]
                    [else
                     (finish next-start next-start
                             (string-append comment "\n"))]))
                (finish form-line-end form-line-end
                        (string-append "\n" comment)))))))

  (define (eval-forms forms env)
    (if (null? forms)
        (values)
        (let loop ([form (car forms)] [rest (cdr forms)])
          (if (null? rest)
              (eval form env)
              (begin
                (eval form env)
                (loop (car rest) (cdr rest)))))))

  (define (eval-program str env)
    (let-values ([(_ remaining) (parse-worksheet str)])
      (eval-forms remaining env)))

)
