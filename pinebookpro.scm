(define-module (pinebookpro))
(use-modules
  (gnu)
  (gnu system locale)
  (config filesystems)
  (config guix-daemon)
  (services tailscale)
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
  cups
  firmware
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

  ;; Currently using tow-boot
  #;(bootloader
    (bootloader-configuration
      (bootloader u-boot-pinebook-pro-rk3399-bootloader)
      (targets '("/dev/mmcblk2"))))

  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets '("/boot/efi"))
      (keyboard-layout keyboard-layout)))

  (initrd-modules '())
  ;(initrd-modules (list "nvme"))        ; By default none.
  (kernel linux-libre-arm64-generic)
  (firmware (list ath9k-htc-firmware))  ; By default none.

  (file-systems
    (cons* (file-system
             (device (file-system-label "Guix_image"))
             (mount-point "/")
             (type "ext4"))
           (file-system
             (mount-point "/boot/efi")
             ;(device (uuid "9146-2C77" 'fat32))
             (device "/dev/mmcblk1p1")
             (type "vfat"))
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
                      "audio" "video")))
                %base-user-accounts))
  (packages
    (append
      (map specification->package
           (list ;"compsize"
                 "cmst"
                 "guix-backgrounds"
                 "guix-simplyblack-sddm-theme"  ; sddm theme
                 "nss-certs"
                 "xterm"

                 "sway"
                 "swayidle"
                 "swaylock"))
      %base-packages))

  (services
    (cons* (service screen-locker-service-type
                    (screen-locker-configuration
                      (name "swaylock")
                      (program (file-append (specification->package "swaylock")
                                              "/bin/swaylock"))
                      (allow-empty-password? #f)
                      (using-pam? #t)
                      (using-setuid? #f)))

           (service openssh-service-type
                    (openssh-configuration
                      (password-authentication? #t)
                      (authorized-keys
                       `(("efraim" ,(local-file "Extras/efraim.pub"))))))

           (service tailscaled-service-type
                    (tailscaled-configuration
                      (package (specification->package "tailscale-bin-arm64"))))

           (service tor-service-type
                    (tor-configuration
                      (hidden-services
                        (list
                          (tor-onion-service-configuration
                            (name "ssh")
                            (mapping '((22 "127.0.0.1:22"))))))))

           #;(service cups-service-type
                    (cups-configuration
                      (web-interface? #t)
                      (default-paper-size "A4")
                      (extensions
                        (list cups-filters hplip-minimal))))

           #;(service mcron-service-type
                    (mcron-configuration
                      ;; Image created with ext4
                      (jobs (%btrfs-maintenance-jobs "/"))))

           (service openntpd-service-type
                    (openntpd-configuration
                      (listen-on '("127.0.0.1" "::1"))
                      (constraints-from '("https://www.google.com/"))))

           (service connman-service-type)

           ;; This one seems to cause the boot process to hang.
           #;(service qemu-binfmt-service-type
                    (qemu-binfmt-configuration
                      ;; We get some architectures for free.
                      (platforms
                        (fold delete %qemu-platforms
                              (lookup-qemu-platforms "arm" "aarch64")))))

           (service earlyoom-service-type
                    (earlyoom-configuration
                      (prefer-regexp "(cc1(plus)?|.rustc-real|ghc|Web Content)")
                      (avoid-regexp "guile")))

           (service zram-device-service-type
                    (zram-device-configuration
                      (size (* 4 (expt 2 30)))
                      (compression-algorithm 'zstd)
                      (priority 100)))

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
                         (theme "guix-simplyblack-sddm")
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

;; guix system image --image-type=efi-raw -L ~/workspace/my-guix/ -L ~/workspace/guix-config/ ~/workspace/guix-config/pinebookpro.scm --system=aarch64-linux
;; sudo cfdisk /dev/sdX to resize /dev/sdX2 to use the remaining space left at the end of the µSD card
;; guix shell e2fsprogs -- sudo resize2fs /dev/sdX2
;; guix shell e2fsck-static -- sudo -E e2fsck /dev/sdX2
