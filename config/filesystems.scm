(define-module (config filesystems)
  #:use-module (gnu system file-systems)
  #:export (%fontconfig
            %guix-temproots))

;; This directory shouldn't exist.
(define %fontconfig
  (file-system
    (device "none")
    (mount-point "/var/cache/fontconfig")
    (type "tmpfs")
    (flags '(read-only))
    (check? #f)))

(define %guix-temproots
  (file-system
    (device "tmpfs")
    (mount-point "/var/guix/temproots")
    (type "tmpfs")
    (check? #f)))
