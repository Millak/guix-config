(define-module (config guix-daemon)
  #:use-module (sqlite3)
  #:use-module (guix gexp)
  #:use-module (gnu services base)
  #:use-module (gnu services mcron)
  #:use-module (gnu packages guile)
  #:export (%guix-configuration
            %substitute-urls
            %authorized-keys
            %extra-options
            %vacuum-database))

(define %substitute-urls
  (list "https://ci.guix.gnu.org"
        ;"http://bp7o7ckwlewr4slm.onion" ; ci.guix.gnu.org
        "https://bordeaux.guix.gnu.org"
        "http://guix.genenetwork.org"
        "https://guix.tobias.gr"))

(define %authorized-keys
  (list (local-file "../Extras/3900XT_publish.pub")
        (local-file "../Extras/E5400_publish.pub")
        (local-file "../Extras/pinebookpro_publish.pub")
        (local-file "../Extras/pine64_publish.pub")
        (local-file "../Extras/g4_publish.pub")
        (local-file "../Extras/unmatched_publish.pub")
        (local-file "../Extras/starfive-vision1.pub")
        (local-file "../Extras/starfive-vision2.pub")
        (local-file "../Extras/ci.guix.gnu.org.pub")
        (local-file "../Extras/bordeaux.guix.gnu.org.pub")
        (local-file "../Extras/guix.genenetwork.org.pub")
        (local-file "../Extras/guix.tobias.gr.pub")))

(define %extra-options
  (list "--gc-keep-derivations=yes"
        "--gc-keep-outputs=yes"))

(define %guix-configuration
  (guix-configuration
    (inherit guix-configuration)
    (substitute-urls %substitute-urls)
    (authorized-keys %authorized-keys)
    (extra-options %extra-options)))

;; Can't be imported for some reason.
(define %vacuum-database
  (let ((vacuum-store
          (gexp->derivation "vacuum-store"
            (with-extensions (list guile-sqlite3)
              (begin
                (use-modules (sqlite3))
                (let ((db (sqlite-open "/var/guix/db/db.sqlite")))
                  (sqlite-exec db "VACUUM;")
                  (sqlite-close db)))))))
    #~(job '(next-hour '(2))
           #~vacuum-store)))
