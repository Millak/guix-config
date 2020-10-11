(use-modules (guix packages)
             (gnu)
             (gnu bootloader u-boot)
             (gnu system locale)
             (config filesystems)
             (config guix-daemon)
             (config os-release)
             (srfi srfi-1))
(use-service-modules
  linux
  ;mcron
  networking
  ssh)
(use-package-modules
  certs
  connman
  linux)

(operating-system
  (host-name "pine64")
  (timezone "Asia/Jerusalem")
  (locale "en_US.UTF-8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))

  (bootloader (bootloader-configuration
                (bootloader u-boot-pine64-plus-bootloader)
                (target "/dev/mmcblk0")))

  (initrd-modules '())
  (kernel linux-libre-arm64-generic)

  (file-systems (cons* (file-system
                         (device (file-system-label "root"))
                         (mount-point "/")
                         (type "ext4"))
                       %guix-temproots
                       %base-file-systems))

  (users (cons (user-account
                (name "efraim")
                (comment "Efraim")
                (group "users")
                (supplementary-groups '("wheel"
                                        "netdev" "kvm"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   btrfs-progs compsize
                   %base-packages))

  (services (cons* (service agetty-service-type
                            (agetty-configuration
                              (extra-options '("-L")) ; no carrier detect
                              (baud-rate "115200")
                              (term "vt100")
                              (tty "ttyS0")))

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
                                       '((3000 "127.0.0.1:3000")))

                   ;; Image created with ext4
                   ;(service mcron-service-type
                   ;         (mcron-configuration
                   ;           (jobs (%btrfs-maintenance-jobs "/"))))

                   (service openntpd-service-type
                            (openntpd-configuration
                              (listen-on '("127.0.0.1" "::1"))
                              (allow-large-adjustment? #t)))

                   (service connman-service-type)
                   (service wpa-supplicant-service-type)

                   ;; Needs no-manual version, depends on pandoc.
                   (service earlyoom-service-type
                            (earlyoom-configuration
                              (earlyoom
                                (let ((base earlyoom))
                                  (package
                                    (inherit base)
                                    (native-inputs
                                      (alist-delete "pandoc"
                                                    (package-native-inputs base))))))))

                   ;; Not supported by linux-libre-arm64-generic
                   ;(service zram-device-service-type
                   ;         (zram-device-configuration
                   ;           (size (expt 2 31))
                   ;           (compression-algorithm 'zstd)
                   ;           (priority 100)))

                   (modify-services
                     %base-services
                     (guix-service-type
                       config =>
                       (guix-configuration
                         (inherit config)
                         (substitute-urls %substitute-urls)
                         (authorized-keys %authorized-keys)
                         (extra-options
                           (cons* "--cores=2" %extra-options)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
