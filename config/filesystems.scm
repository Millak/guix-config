(define-module (config filesystems)
  #:use-module (gnu system file-systems)
  #:use-module (gnu services mcron)
  #:use-module (gnu packages linux)
  #:use-module (guix gexp)
  #:export (%btrfs-maintenance-jobs
            %guix-temproots
            %tmp-tmpfs))

(define (%btrfs-maintenance-jobs mount-point)
  (list
    #~(job '(next-hour '(3))
           (string-append #$btrfs-progs "/bin/btrfs "
                          "scrub " "start " "-c " "idle "
                          #$mount-point))
    #~(job '(next-hour '(5))
           (string-append #$btrfs-progs "/bin/btrfs "
                          "balance " "start "  "-dusage=70 " "-musage=80 "
                          #$mount-point))))

(define %guix-temproots
  (file-system
    (device "tmpfs")
    (mount-point "/var/guix/temproots")
    (type "tmpfs")
    (flags '(no-suid no-dev no-exec))
    (options "size=10M")
    (check? #f)))

;; Defaults to 50%
(define %tmp-tmpfs
  (file-system
    (device "tmpfs")
    (mount-point "/tmp")
    (type "tmpfs")
    (flags '(no-suid))
    (check? #f)))
