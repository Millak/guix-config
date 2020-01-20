(define-module (config guix-daemon)
  #:use-module (guix gexp)
  #:use-module (gnu services base)
  #:export (%guix-configuration
            %substitute-urls
            %authorized-keys
            %extra-options))

(define %substitute-urls
  (list "http://192.168.1.183:3000" ; E2140
        "http://192.168.1.217:3000" ; E5400
        "http://192.168.1.209:3000" ; macbook41
        "https://ci.guix.gnu.org"
        "https://bayfront.guixsd.org"
        "http://guix.genenetwork.org"
        "https://guix.tobias.gr"))

(define %authorized-keys
  (list (local-file "../Extras/ci.guix.gnu.org.pub")
        (local-file "../Extras/E2140_publish.pub")
        (local-file "../Extras/E5400_publish.pub")
        (local-file "../Extras/macbook41_publish.pub")
        (local-file "../Extras/guix.genenetwork.org.pub")
        (local-file "../Extras/guix.tobias.gr.pub")))

(define %extra-options
  (list "--gc-keep-derivations=yes"
        "--gc-keep-outputs=yes"))

(define %guix-configuration
  (guix-configuration
    (inherit (@@ (gnu services base) %default-guix-configuration))
    (substitute-urls %substitute-urls)
    (authorized-keys %authorized-keys)
    (extra-options %extra-options)))