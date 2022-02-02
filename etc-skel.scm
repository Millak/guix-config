(define-module (etc-skel)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu services)
  #:use-module (guix gexp))

;;;

(define %gdbinit
  (plain-file "dot-gdbinit" "\
# Tell GDB where to look for separate debugging files.
guile
(use-modules (gdb))
(execute (string-append \"set debug-file-directory \"
                        (or (getenv \"GDB_DEBUG_FILE_DIRECTORY\")
                            \"~/.guix-profile/lib/debug\")))
end

# Authorize extensions found in the store, such as the
# pretty-printers of libstdc++.
set auto-load safe-path /gnu/store/*/lib\n"))

(define %guile
  (plain-file "dot-guile"
              "(cond ((false-if-exception (resolve-interface '(ice-9 readline)))
       =>
       (lambda (module)
         ;; Enable completion and input history at the REPL.
         ((module-ref module 'activate-readline))))
      (else
       (display \"Consider installing the 'guile-readline' package for
convenient interactive line editing and input history.\\n\\n\")))

      (unless (getenv \"INSIDE_EMACS\")
        (cond ((false-if-exception (resolve-interface '(ice-9 colorized)))
               =>
               (lambda (module)
                 ;; Enable completion and input history at the REPL.
                 ((module-ref module 'activate-colorized))))
              (else
               (display \"Consider installing the 'guile-colorized' package
for a colorful Guile experience.\\n\\n\"))))\n"))

(define %nanorc
  (plain-file "nanorc" "\
# Include all the syntax highlighting modules.
include /run/current-system/profile/share/nano/*.nanorc\n"))

(define %xdefaults
  (plain-file "dot-Xdefaults" "\
XTerm*utf8: always
XTerm*metaSendsEscape: true\n"))

;;;

(define etc-skel
  (home-environment
    (services
      (list
        (service home-bash-service-type)
        (service home-fish-service-type)
        (service home-zsh-service-type)

        (service home-files-service-type
         `(("config/nano/nanorc" ,%nanorc)
           ("gdbinit" ,%gdbinit)
           ("guile" ,%guile)
           ("Xdefaults" ,%xdefaults)))))))

etc-skel
