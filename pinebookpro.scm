(define-module (pinebookpro))
(use-modules
  (gnu)
  (gnu bootloader u-boot)
  (gnu system locale)
  (config filesystems)
  (config guix-daemon)
  (srfi srfi-1))
;(use-modules (nongnu packages linux))
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
  cups
  linux)

(operating-system
  (host-name "pbp")
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
      (bootloader u-boot-pinebook-pro-rk3399-bootloader)
      (targets '("/dev/vda"))           ; for creating the disk image
      ;(targets '("/dev/mmcblk0"))      ; SD card/eMMC (SD priority) storage
      (keyboard-layout keyboard-layout)))

  (initrd-modules '())                  ; By default none.
  (kernel linux-libre-arm64-generic)
  ;(firmware '())

  ;; Remove after zram?
  ;(swap-devices
  ;  (list (swap-space
  ;          (target "/swapfile"))))

  (file-systems
    (cons* (file-system
             (device (file-system-label "root"))
             (mount-point "/")
             (type "ext4"))
           ;%tmp-tmpfs
           %guix-temproots
           %base-file-systems))

  (users (cons* (user-account
                  (name "efraim")
                  (comment "Efraim Flashner")
                  (group "users")
                  (home-directory "/home/efraim")
                  (password "$6$4t79wXvnVk$bjwOl0YCkILfyWbr1BBxiPxJ0GJhdFrPdbBjndFjZpqHwd9poOpq2x5WtdWPWElK8tQ8rHJLg3mJ4ZfjrQekL1")
                  (supplementary-groups
                    '("wheel" "netdev" "kvm"
                      ;"lp" "lpadmin"       ; CUPS
                      ;"libvirt"            ; libvirt
                      "audio" "video")))
                %base-user-accounts))
  (packages
    (append
      (list (specification->package "nss-certs")
            ;(specification->package "compsize")
            (specification->package "econnman")
            ;(specification->package "virt-manager")
            )
      %base-packages))

  (services
    (cons* (service enlightenment-desktop-service-type)

           (service openssh-service-type
                    (openssh-configuration
                      (password-authentication? #t)
                      (authorized-keys
                       `(("efraim" ,(local-file "Extras/efraim.pub"))))))

           (service tor-service-type)
           (tor-hidden-service "ssh"
                               '((22 "127.0.0.1:22")))

           ;(service cups-service-type
           ;         (cups-configuration
           ;           (web-interface? #t)
           ;           (default-paper-size "A4")
           ;           (extensions
           ;             (list cups-filters hplip-minimal))))

           ;(service mcron-service-type
           ;         (mcron-configuration
           ;           ;; Image created with ext4
           ;           (jobs (%btrfs-maintenance-jobs "/"))))

           (service openntpd-service-type
                    (openntpd-configuration
                      (listen-on '("127.0.0.1" "::1"))
                      (constraints-from '("https://www.google.com/"))))

           (service connman-service-type)

           ;(service libvirt-service-type
           ;         (libvirt-configuration
           ;           (unix-sock-group "libvirt")))
           ;(service virtlog-service-type)

           (service qemu-binfmt-service-type
                    (qemu-binfmt-configuration
                      ;; We get some architectures for free.
                      (platforms
                        (fold delete %qemu-platforms
                              (lookup-qemu-platforms "arm" "aarch64")))))

           (service earlyoom-service-type
                    (earlyoom-configuration
                      (prefer-regexp "(cc1(plus)?|.rustc-real|ghc|Web Content)")
                      (avoid-regexp "enlightenment")))

           ;; Not yet supported by linux-libre-arm64-generic
           ;(service zram-device-service-type
           ;         (zram-device-configuration
           ;           (size (* 4 (expt 2 30)))
           ;           (compression-algorithm 'zstd)
           ;           (priority 100)))

           (remove (lambda (service)
                     (let ((type (service-kind service)))
                       (or (memq type
                                 (list
                                   modem-manager-service-type
                                   network-manager-service-type
                                   ntp-service-type
                                   screen-locker-service-type))
                           (eq? 'network-manager-applet
                                (service-type-name type)))))
                   (modify-services
                     %desktop-services
                     (sddm-service-type
                       config =>
                       (sddm-configuration
                         (inherit config)
                         (display-server "wayland")))

                     (guix-service-type
                       config =>
                       (guix-configuration
                         (inherit config)
                         ;; Rely on btrfs compression.
                         ;(log-compression 'none)
                         (discover? #t)
                         (substitute-urls %substitute-urls)
                         (authorized-keys %authorized-keys)
                         (extra-options
                           (cons* "--cores=3" %extra-options))))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
