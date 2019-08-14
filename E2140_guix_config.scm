(use-modules (guix store)
             (gnu)
             (gnu system locale)
             (srfi srfi-1))
(use-service-modules admin desktop mcron networking ssh xorg)
(use-package-modules certs fonts gnome linux pulseaudio)

(define %btrfs-scrub-root
  #~(job '(next-hour '(3))
         (string-append #$btrfs-progs "/bin/btrfs scrub start -c 3 /")))

(define %btrfs-scrub-data
  #~(job '(next-hour '(4))
         (string-append #$btrfs-progs "/bin/btrfs scrub start -c 3 /data")))

(define %btrfs-balance-root
  #~(job '(next-hour '(5))
         (string-append #$btrfs-progs "/bin/btrfs balance start -dusage=50 -musage=70 /")))

(define %btrfs-balance-data
  #~(job '(next-hour '(6))
         (string-append #$btrfs-progs "/bin/btrfs balance start -dusage=50 -musage=70 /data")))

(define %os-release-file
  (plain-file "os-release"
              (string-append
                "NAME=\"GNU Guix\"\n"
                "PRETTY_NAME=\"GNU Guix\"\n"
                "VERSION=\""((@ (guix packages) package-version) (@ (gnu packages package-management) guix))"\"\n"
                "ID=guix\n"
                "HOME_URL=\"https://www.gnu.org/software/guix/\"\n"
                "SUPPORT_URL=\"https://www.gnu.org/software/guix/help/\"\n"
                "BUG_REPORT_URL=\"mailto:bug-guix@gnu.org\"\n")))

(define (remove-services types services)
  (remove (lambda (service)
            (any (lambda (type)
                   (eq? (service-kind service) type))
                 types))
          services))

(operating-system
  (host-name "E2140")
  (timezone "Asia/Jerusalem")
  (locale "en_US.utf8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.utf8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.utf8"))))

  ;; Assuming /dev/sdX is the target hard disk, and "my-root"
  ;; is the label of the target root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (target "/dev/sdb")))

  (kernel-arguments '("zswap.enabled=1"
                      "zswap.compressor=lz4"
                      "zswap.zpool=z3fold"
                      ;; Required to run X32 software and VMs
                      ;; https://wiki.debian.org/X32Port
                      "syscall.x32=y"))

  (file-systems (cons* (file-system
                         (device (file-system-label "my-root"))
                         (mount-point "/")
                         (type "btrfs")
                         (options "autodefrag,compress=lzo"))
                       (file-system
                         (device (file-system-label "data"))
                         (mount-point "/data")
                         (type "btrfs")
                         (options "autodefrag,compress=lzo"))
                       ;; This directory shouldn't exist
                       (file-system
                         (device "none")
                         (mount-point "/var/cache/fontconfig")
                         (type "tmpfs")
                         (flags '(read-only))
                         (check? #f))
                       (file-system
                         (device "none")
                         (mount-point "/var/guix/temproots")
                         (type "tmpfs")
                         (check? #f))
                       %base-file-systems))

  (swap-devices '("/dev/sda1" "/dev/sdb1" "/dev/sdc1"))

  (users (cons* (user-account
                 (name "efraim")
                 (comment "Efraim")
                 (group "users")
                 (supplementary-groups '("wheel" "netdev"
                                         "audio" "video"))
                 (home-directory "/home/efraim"))
                (user-account
                 (name "rivka")
                 (comment "Rivka")
                 (group "users")
                 (supplementary-groups `("netdev"
                                         "audio" "video"))
                 (home-directory "/home/rivka"))
                (user-account
                 (name "kids")
                 (comment "both kids")
                 (group "users")
                 (supplementary-groups '("netdev"
                                         "audio" "video"))
                 (home-directory "/home/kids"))
                %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   gvfs              ;for user mounts
                   btrfs-progs pavucontrol
                   font-terminus font-dejavu
                   %base-packages))

  (services (cons* (service xfce-desktop-service-type)

                   (simple-service 'os-release etc-service-type
                                   `(("os-release" ,%os-release-file)))

                   (service guix-publish-service-type
                            (guix-publish-configuration
                              (host "0.0.0.0")
                              (port 3000)
                              ;; This machine is slow;
                              ;; support only minimal compression
                              (compression '(("lzip" 1) ("gzip" 1)))))

                   (service openssh-service-type
                            (openssh-configuration
                              (x11-forwarding? #t)
                              (extra-content "StreamLocalBindUnlink yes")))

                   (service tor-service-type)
                   (tor-hidden-service "ssh"
                                       '((22 "127.0.0.1:22")))
                   (tor-hidden-service "guix-publish"
                                       ; fqq67aawbuqnxzng.onion
                                       '((3000 "127.0.0.1:3000")))
                   (service rottlog-service-type)
                   (service mcron-service-type
                            (mcron-configuration
                             (jobs (list %btrfs-scrub-root
                                         %btrfs-scrub-data
                                         %btrfs-balance-root
                                         %btrfs-balance-data))))

                   (service slim-service-type)

                   (modify-services (remove-services
                                      (list
                                        gdm-service-type)
                                      %desktop-services)
                     (guix-service-type
                       config =>
                       (guix-configuration
                         (inherit config)
                         (substitute-urls
                           (list "http://192.168.1.209:3000" ; macbook41
                                 "http://firefly.lan:8181"
                                 "https://ci.guix.gnu.org"
                                 "https://bayfront.guixsd.org"
                                 "https://guix.tobias.gr"))
                         (authorized-keys
                           (list (local-file "Extras/ci.guix.gnu.org.pub")
                                 (local-file "Extras/firefly_publish.pub")
                                 (local-file "Extras/macbook41_publish.pub")
                                 (local-file "Extras/guix.tobias.gr.pub")))
                         (extra-options
                           (list "--gc-keep-derivations=yes"
                                 "--gc-keep-outputs=yes"))))
                     (network-manager-service-type
                       config =>
                       (network-manager-configuration
                         (inherit config)
                         (dns "dnsmasq")
                         (vpn-plugins (list network-manager-openconnect))))
                     (ntp-service-type
                       config =>
                       (ntp-configuration
                         (inherit config)
                         (allow-large-adjustment? #t))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
