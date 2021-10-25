(define-module (config guix-daemon)
  #:use-module (guix gexp)
  #:use-module (gnu services base)
  #:export (%guix-configuration
            %substitute-urls
            %authorized-keys
            %extra-options))

(define %substitute-urls
  (list "https://ci.guix.gnu.org"
        ;"http://bp7o7ckwlewr4slm.onion" ; ci.guix.gnu.org
        "https://bayfront.guix.gnu.org"
        "https://bordeaux.guix.gnu.org"
        "http://guix.genenetwork.org"
        "https://guix.tobias.gr"))

(define %authorized-keys
  (list (local-file "../Extras/3900XT_publish.pub")
        (local-file "../Extras/3900XT_childhurd_publish.pub")
        (local-file "../Extras/E5400_publish.pub")
        (local-file "../Extras/pine64_publish.pub")
        (local-file "../Extras/g4_publish.pub")
        (local-file "../Extras/unmatched_publish.pub")
        (local-file "../Extras/ci.guix.gnu.org.pub")
        (local-file "../Extras/bayfront.guix.gnu.org.pub")
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
