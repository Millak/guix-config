(define-module (3900XT))
(use-modules
  (gnu)
  (gnu system locale)
  (config filesystems)
  (config guix-daemon)
  (config os-release)
  (srfi srfi-1))
(use-service-modules
  cups
  desktop
  linux
  mcron
  networking
  sddm
  ssh
  virtualization
  xorg)
(use-package-modules
  cups)

(operating-system
  (host-name "3900XT")
  (timezone "Asia/Jerusalem")
  (locale "en_IL.utf8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))
  (keyboard-layout
    (keyboard-layout "us" "altgr-intl"))

  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (target "/boot/efi")
      (keyboard-layout keyboard-layout)))

  (file-systems
    (cons* (file-system
             (mount-point "/")
             (device
               (uuid "20048579-a0bd-4180-8ea3-4b546309fb3b"
                     'btrfs))
             (type "btrfs")
             (options "autodefrag,compress-force=zstd,discard,space_cache=v2"))
           (file-system
             (mount-point "/boot/efi")
             (device (uuid "9146-2C77" 'fat32))
             (type "vfat"))
           %tmp-tmpfs
           %guix-temproots
           %base-file-systems))

  (users (cons* (user-account
                  (name "efraim")
                  (comment "Efraim Flashner")
                  (group "users")
                  (home-directory "/home/efraim")
                  (supplementary-groups
                    '("wheel" "netdev" "kvm"
                      "lp" "lpadmin"
                      "libvirt"
                      "audio" "video")))
                %base-user-accounts))
  (packages
    (append
      (list (specification->package "nss-certs")
            (specification->package "compsize")
            (specification->package "econnman")
            (specification->package "virt-manager"))
      %base-packages))

  (services
    (cons* (service enlightenment-desktop-service-type)

           (simple-service 'os-release etc-service-type
                           `(("os-release" ,%os-release-file)))

           (service guix-publish-service-type
                    (guix-publish-configuration
                      (host "0.0.0.0")
                      (port 3000)
                      (advertise? #t)))
           (service openssh-service-type
                    (openssh-configuration
                      (password-authentication? #t)))

           (service tor-service-type)
           (tor-hidden-service "ssh"
                               '((22 "127.0.0.1:22")))
           (tor-hidden-service "guix-publish"
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

           (service earlyoom-service-type
                    (earlyoom-configuration
                      (prefer-regexp "(cc1(plus)?|.rustc-real|ghc|Web Content)")
                      (avoid-regexp "enlightenment")))

           (service zram-device-service-type
                    (zram-device-configuration
                      (size (* 16 (expt 2 30)))
                      (compression-algorithm 'zstd)
                      (priority 100)))

           (service sddm-service-type
                    (sddm-configuration
                      (display-server "x11")))

           ;(set-xorg-configuration
           ;  (xorg-configuration
           ;    (keyboard-layout keyboard-layout)))

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
                         (discover? #t)
                         (substitute-urls %substitute-urls)
                         (authorized-keys %authorized-keys)
                         (extra-options
                           (cons* "--max-jobs=5" %extra-options))))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
