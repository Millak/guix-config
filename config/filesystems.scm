(define-module (config filesystems)
  #:use-module (gnu system file-systems)
  #:use-module (gnu services mcron)
  #:use-module (gnu packages linux)
  #:use-module (guix gexp)
  #:export (%btrfs-maintenance-jobs
            %fontconfig
            %guix-temproots))

(define (%btrfs-maintenance-jobs mount-point)
  (list
    #~(job '(next-hour '(3))
           (invoke #$(file-append btrfs-progs "/bin/btrfs")
                   "scrub" "start" "-c" "3" mountpoint))
    #~(job '(next-hour '(5))
           (invoke #$(file-append btrfs-progs "/bin/btrfs")
                   "balance" "start" "-dusage=50" "-musage=70" mountpoint))))

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
