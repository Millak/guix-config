(define-module (config filesystems)
  #:use-module (gnu system file-systems)
  #:use-module (gnu services mcron)
  #:use-module (gnu packages linux)
  #:use-module (guix gexp)
  #:export (%btrfs-maintenance-jobs
            %guix-temproots))

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
    (check? #f)))
