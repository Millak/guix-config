(use-modules (guix store)
             (guix gexp)
             (gnu)
             (gnu system locale)
             (config filesystems)
             (config guix-daemon)
             (config os-release)
             (srfi srfi-1))
(use-service-modules admin cups desktop linux mcron networking sddm security-token ssh virtualization xorg)
(use-package-modules certs connman cups gnome linux virtualization)

(operating-system
  (host-name "E5400")
  (timezone "Asia/Jerusalem")
  (locale "en_US.UTF-8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))

  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (target "/dev/sda")))

  (file-systems (cons* (file-system
                         (device (file-system-label "root"))
                         (mount-point "/")
                         (type "btrfs")
                         (options "autodefrag,compress-force=zstd,discard,ssd_spread,space_cache=v2"))
                       (file-system
                         (device (file-system-label "data"))
                         (mount-point "/data")
                         (type "ext4"))
                       %guix-temproots
                       %base-file-systems))

  (kernel linux-libre-5.4)
  (swap-devices '("/dev/sda1"))

  (users (cons (user-account
                (name "efraim")
                (comment "Efraim")
                (group "users")
                (supplementary-groups '("wheel" "netdev" "kvm"
                                        "lp" "lpadmin"
                                        "libvirt"
                                        "audio" "video"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   cups
                   hicolor-icon-theme
                   econnman
                   btrfs-progs compsize
                   virt-manager
                   %base-packages))

  (services (cons* (service enlightenment-desktop-service-type)

                   (simple-service 'os-release etc-service-type
                                   `(("os-release" ,%os-release-file)))

                   (service guix-publish-service-type
                            (guix-publish-configuration
                              (host "0.0.0.0")
                              (port 3000)))
                   (service openssh-service-type
                            (openssh-configuration
                              (password-authentication? #t)))

                   (service tor-service-type)
                   (tor-hidden-service "ssh"
                                       '((22 "127.0.0.1:22")))
                   (tor-hidden-service "guix-publish"
                                       ;jlcmm5lblot62p4txmplf66d76bsrfs4ilhcwaswjdulf6htvntxztad.onion
                                       '((3000 "127.0.0.1:3000")))

                   (service cups-service-type
                            (cups-configuration
                              (web-interface? #t)
                              (default-paper-size "A4")
                              (extensions
                                (list cups-filters hplip-minimal))))

                   (service mcron-service-type
                            (mcron-configuration
                              (jobs (%btrfs-maintenance-jobs "/"))))

                   (service openntpd-service-type
                            (openntpd-configuration
                              (listen-on '("127.0.0.1" "::1"))
                              (allow-large-adjustment? #t)))

                   (service connman-service-type)

                   (service libvirt-service-type
                            (libvirt-configuration
                              (unix-sock-group "libvirt")))
                   (service virtlog-service-type)

                   (service pcscd-service-type)
                   (service earlyoom-service-type
                            (earlyoom-configuration
                              (minimum-free-swap 50)))

                   (service zram-device-service-type
                            (zram-device-configuration
                              (size (* 2 (expt 2 30)))
                              (compression-algorithm 'zstd)
                              (priority 100)))

                   (service sddm-service-type
                            (sddm-configuration
                              (display-server "wayland")))

                   (remove (lambda (service)
                             (let ((type (service-kind service)))
                               (or (memq type
                                         (list
                                           gdm-service-type
                                           modem-manager-service-type
                                           network-manager-service-type
                                           ntp-service-type
                                           screen-locker-service-type))
                                   (eq? 'network-manager-applet
                                        (service-type-name type)))))
                           (modify-services
                             %desktop-services
                             (guix-service-type
                               config =>
                               (guix-configuration
                                 (inherit config)
                                 (substitute-urls %substitute-urls)
                                 (authorized-keys %authorized-keys)
                                 (extra-options %extra-options)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
