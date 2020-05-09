(use-modules (guix store)
             (guix gexp)
             (gnu)
             (gnu system locale)
             (config filesystems)
             (config guix-daemon)
             (config os-release)
             (srfi srfi-1))
(use-service-modules admin desktop mcron networking ssh xorg)
(use-package-modules certs fonts gnome linux pulseaudio)

(define (remove-services types services)
  (remove (lambda (service)
            (any (lambda (type)
                   (eq? (service-kind service) type))
                 types))
          services))

(operating-system
  (host-name "E2140")
  (timezone "Asia/Jerusalem")
  (locale "en_US.UTF-8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))
  (locale-libcs (list glibc-2.29 (canonical-package glibc)))

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
                         (options "autodefrag,compress-force=zstd"))
                       (file-system
                         (device (file-system-label "data"))
                         (mount-point "/data")
                         (type "btrfs")
                         (options "autodefrag,compress-force=zstd"))
                       %guix-temproots
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
                   pavucontrol
                   btrfs-progs compsize
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
                   (service mcron-service-type
                            (mcron-configuration
                              (jobs (append (%btrfs-maintenance-jobs "/")
                                            (%btrfs-maintenance-jobs "/data")))))

                   (service slim-service-type)

                   (modify-services (remove-services
                                      (list
                                        gdm-service-type)
                                      %desktop-services)
                     (guix-service-type
                       config =>
                       (guix-configuration
                         (inherit config)
                         (substitute-urls %substitute-urls)
                         (authorized-keys %authorized-keys)
                         (extra-options %extra-options)))
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
