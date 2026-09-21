(library (worksheet-env)
  (export
    src-root
    object-directory
    prepare-library-directories!
    default-import-specs
    read-forms
    parse-worksheet
    make-worksheet-environment
    eval-forms
    eval-program)
  (import (chezscheme))

  (define src-root "/home/dharmatech/src")

  (define object-directory
    "/home/dharmatech/journal/2026-09-21-chezmacs-mpl/eo")

  (define lib-root
    "/home/dharmatech/journal/2026-09-21-chezmacs-mpl/lib")

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
