(use-modules (guix store)
             (gnu)
             (srfi srfi-1))
(use-service-modules admin networking ssh sysctl)
(use-package-modules certs)

(define %os-release-file
  (plain-file "os-release"
              (string-append
                "NAME=\"Guix System\"\n"
                "PRETTY_NAME=\"Guix System\"\n"
                "VERSION=\""((@ (guix packages) package-version) (@ (gnu packages package-management) guix))"\"\n"
                "ID=guix\n"
                "HOME_URL=\"https://www.gnu.org/software/guix/\"\n"
                "SUPPORT_URL=\"https://www.gnu.org/software/guix/help/\"\n"
                "BUG_REPORT_URL=\"mailto:bug-guix@gnu.org\"\n")))

(define %efraim-ssh-key
  (plain-file "id_ecdsa.pub"
              "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBkVckSY5TpAONmDG8Hy+vvxbIwr9gcLVPexFjgwS/BKsSn4GR/rqPvyYJdeJeMvAiaOJsNz8M3z6nGvoFe32I4= efraim@flashner.co.il"))

(define %ci.guix.gnu.org.pub
  (plain-file "ci.guix.gnu.org.pub"
              "(public-key
                 (ecc
                   (curve Ed25519)
                   (q #8D156F295D24B0D9A86FA5741A840FF2D24F60F7B6C4134814AD55625971B394#)))"))

(define this-file
  (local-file (basename (assoc-ref (current-source-location) 'filename))
              "config.scm"))

(operating-system
  (host-name "guix_vm")
  (timezone "Etc/UTC")
  (locale "en_US.UTF-8")

  ;; Choose either grub or grub-efi.
  ;; Check 'lsblk' if grub for '/dev/vda' replacement.
  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (target "/dev/vda")
                ;(bootloader grub-efi-bootloader)
                ;(target "/boot/efi")
                (terminal-outputs '(console))))

  (firmware '())

  (kernel-arguments '("zswap.enabled=1"))

  (file-systems (cons* (file-system
                         (mount-point "/")
                         ;; lsblk --output MOUNTPOINT,UUID
                         (device (uuid "FILL_ME_IN"))
                         (type "ext4"))
                       ;; This is only necessary if you're using EFI.
                       ;(file-system
                       ;  (device (uuid "FILL_ME_IN" 'fat))
                       ;  (mount-point "/boot/efi")
                       ;  (type "vfat"))
                       (file-system
                         (device "none")
                         (mount-point "/var/guix/temproots")
                         (type "tmpfs")
                         (check? #f))
                       %base-file-systems))

  ;; Be sure you create the swpfile first!
  ;(swap-devices '("/swapfile"))

  (users (cons (user-account
                (name "efraim")
                (comment "Efraim")
                (group "users")
                (supplementary-groups '("wheel" "netdev" "kvm"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   %base-packages))

  (services (cons* (simple-service 'os-release etc-service-type
                                   `(("os-release" ,%os-release-file)))

                   ;; Copy this file to /etc/config.scm in the OS.
                   (simple-service 'config-file etc-service-type
                                   `(("config.scm" ,this-file)))

                   (service openssh-service-type
                            (openssh-configuration
                              ;; Remove this after setting a password.
                              (allow-empty-passwords? #t)
                              (password-authentication? #f)
                              (authorized-keys
                                `(("efraim" ,%efraim-ssh-key)))))

                   (service sysctl-service-type
                            (sysctl-configuration
                              (settings '(("zswap.compressor" . "lz4")
                                          ("zswap.zpool" . "z3fold")))))

                   ;(service tor-service-type)
                   ;(tor-hidden-service "ssh"
                   ;                    '((22 "127.0.0.1:22")))

                   (service rottlog-service-type)

                   (service openntpd-service-type
                            (openntpd-configuration
                              (listen-on '("127.0.0.1" "::1"))
                              (allow-large-adjustment? #t)))

                   ;; For networking
                   (service dhcp-client-service-type)

                   (modify-services %base-services
                     ;; The default udev rules are not needed in a VM.
                     (udev-service-type config =>
                                        (udev-configuration
                                          (inherit config)
                                          (rules '())))
                     (guix-service-type config =>
                                        (guix-configuration
                                          (inherit config)
                                          (substitute-urls
                                            (list "https://ci.guix.gnu.org"
                                                  "https://bayfront.guixsd.org"))
                                          (authorized-keys
                                            (list %ci.guix.gnu.org.pub)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
