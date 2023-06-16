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
  linux)

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

  (bootloader (bootloader-configuration
                (bootloader u-boot-sifive-unmatched-bootloader)
                (targets '("/dev/mmcblk0"))))   ; SD card/eMMC (SD priority) storage

  (firmware '())
  ;; Plenty of options for initrd modules.
  (initrd-modules '())
  ;(initrd-modules '("nvme"))
  ;(initrd-modules '("mmc_spi"))
  ;; https://github.com/zhaofengli/nixos-riscv64/blob/master/nixos/unmatched.nix
  ;(initrd-modules '("nvme" "mmc_block" "mmc_spi" "spi_sifive" "spi_nor"))
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
                    '("wheel" "netdev"
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

           ;; Image created with ext4
           ;(service mcron-service-type
           ;         (mcron-configuration
           ;           (jobs (%btrfs-maintenance-jobs "/"))))

           (service openntpd-service-type
                    (openntpd-configuration
                      (listen-on '("127.0.0.1" "::1"))
                      ;; Prevent moving to year 2116.
                      (constraints-from '("https://www.google.com/"))))

           (service dhcp-client-service-type)

           (service earlyoom-service-type
                    (earlyoom-configuration
                      (prefer-regexp "(cc1(plus)?|.rustc-real|Web Content)")
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
                 (substitute-urls '())   ; Offload machine
                 (authorized-keys %authorized-keys)
                 (extra-options
                   (cons* "--cache-failures" %extra-options)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))

;; guix system image --image-type=unmatched-raw -L ~/workspace/guix-config/ ~/workspace/guix-config/unmatched.scm --system=riscv64-linux
