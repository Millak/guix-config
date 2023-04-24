(define-module (unmatched))
(use-modules (guix packages)
             (gnu)
             (gnu bootloader u-boot)
             (gnu system locale)
             (config filesystems)
             (config guix-daemon)
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

;; For (gnu bootloader u-boot)
(use-modules (gnu packages bootloaders))

(define install-sifive-unmatched-u-boot
  #~(lambda (bootloader root-index image)
      (let ((spl (string-append bootloader "/libexec/spl/u-boot-spl.bin"))
            (u-boot (string-append bootloader "/libexec/u-boot.itb")))
        ;; https://source.denx.de/u-boot/u-boot/-/blob/master/doc/board/sifive/unmatched.rst
        (write-file-on-device spl (stat:size (stat spl))
                              image (* 34 512))
        (write-file-on-device u-boot (stat:size (stat u-boot))
                              image (* 2082 512)))))

;; To prepare the disk: (from gptfdisk)
;;sgdisk -g --clear --set-alignment=1 \
;;    --new=1:34:+1M: --change-name=1:spl --typecode=1:5b193300-fc78-40cd-8002-e86c45580b47 \
;;    --new=2:2082:+4M: --change-name=2:uboot --typecode=2:2e54b353-1271-4842-806f-e436d6af6985 \
;;    --new=3:16384:282623    --change-name=3:boot --typecode=3:0x0700 \    ; vfat
;;    --new=4:286720:13918207 --change-name=4:root --typecode=4:0x8300 \    ; ext4
;;    [block device]

(define u-boot-sifive-unmatched-bootloader
  (bootloader
   (inherit u-boot-bootloader)
   (package u-boot-sifive-unmatched)
   (disk-image-installer install-sifive-unmatched-u-boot)))

;; OS starts from here:

(operating-system
  (host-name "unmatched")
  (timezone "Asia/Jerusalem")
  (locale "en_IL.utf8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))
  (keyboard-layout
    (keyboard-layout "us" "altgr-intl"))

  ;; No need for glibc-2.31.
  (locale-libcs (list (canonical-package glibc)))

  ;(bootloader (bootloader-configuration
  ;              (bootloader u-boot-sifive-unmatched-bootloader)
  ;              (targets '("/dev/mmcblk0"))))   ; SD card/eMMC (SD priority) storage
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))))

  (firmware '())
  ;; Plenty of options for initrd modules.
  (initrd-modules '())
  ;(initrd-modules (cons "nvme" %base-initrd-modules))
  ;(initrd-modules '("nvme"))
  ;(initrd-modules '("mmc_spi"))
  ;; https://github.com/zhaofengli/nixos-riscv64/blob/master/nixos/unmatched.nix
  ;(initrd-modules '("nvme" "mmc_block" "mmc_spi" "spi_sifive" "spi_nor"))
  ;; Try the gernic kernel first.
  (kernel linux-libre-riscv64-generic)

  ;(swap-devices
  ;  (list (swap-space
  ;          (target "/swapfile"))))

  (file-systems
    (cons* (file-system
             (device (file-system-label "root"))
             (mount-point "/")
             (type "ext4"))
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
                      ;"lp" "lpadmin"
                      ;"libvirt"
                      "audio" "video")))
                %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   ;btrfs-progs compsize
                   %base-packages))

  (services
    (cons* (service openssh-service-type
                    (openssh-configuration
                      (openssh (specification->package "openssh-sans-x"))
                      (authorized-keys
                       `(("efraim" ,(local-file "Extras/efraim.pub"))))))

           ;(service tor-service-type)
           ;(tor-hidden-service "ssh"
           ;                    '((22 "127.0.0.1:22")))
           ;(tor-hidden-service "guix-publish"
           ;                    '((3000 "127.0.0.1:3000")))

           ;; Image created with ext4
           ;(service mcron-service-type
           ;         (mcron-configuration
           ;           (jobs (%btrfs-maintenance-jobs "/"))))

           (service openntpd-service-type
                    (openntpd-configuration
                      (listen-on '("127.0.0.1" "::1"))
                      ;; Prevent moving to year 2116.
                      (constraints-from '("https://www.google.com/"))))

           ;(service connman-service-type)
           ;(service wpa-supplicant-service-type)
           (service dhcp-client-service-type)

           ;; Skip go for now
           (service earlyoom-service-type
                    (earlyoom-configuration
                      (prefer-regexp "(cc1(plus)?|.rustc-real|ghc|Web Content)")
                      (avoid-regexp "guile")))

           (service zram-device-service-type
                    (zram-device-configuration
                      (size (* 8 (expt 2 30)))
                      (compression-algorithm 'zstd)
                      (priority 100)))

           (modify-services
             %base-services
             (guix-service-type
               config =>
               (guix-configuration
                 (inherit config)
                 (substitute-urls '())   ; No riscv64 substitutes.
                 (authorized-keys %authorized-keys)
                 (extra-options
                   (cons* "--cache-failures" %extra-options)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))

;; guix system image --image-type=unmatched-raw -L ~/workspace/guix-config/ ~/workspace/guix-config/unmatched.scm --system=riscv64-linux
