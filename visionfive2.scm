(define-module (visionfive2))
(use-modules (guix packages)
             (gnu)
             (gnu bootloader grub)
             (gnu bootloader u-boot)
             (gnu bootloader extlinux)
             (gnu system locale)
             (config filesystems)
             (config guix-daemon)
             (srfi srfi-1))
(use-service-modules
  linux
  mcron
  networking
  ssh)
(use-package-modules
  connman
  linux)

;; To prepare the disk: (from gptfdisk)
;;sgdisk -g --clear --set-alignment=1 \
;;    --new=1:0:+1M: \
;;    --new=2:0:+100M: --typecode=2:EF00 \
;;    --new=3:0:-1M:    --attributes 3:set:2 -d 1 \
;;    [block device]

(use-modules (gnu packages bootloaders)
             (guix utils)
             (guix git-download))

;; Some 40ish commits on top of upstream u-boot 2022.04-rc2
(define u-boot-starfive-visionfive2
  (let ((base (make-u-boot-package "starfive_jh7100_visionfive_smode" "riscv64-linux-gnu"))
        (commit "ac0ac696256abf412826d74ee918dd417e207d7b"))
    (package
      (inherit base)
      (version (git-version "VF2_v2.11.5" "2" commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                       (url "https://github.com/starfive-tech/u-boot")
                       (commit commit)))
                (file-name (git-file-name "starfive-visionfive2-u-boot" version))
                (sha256
                 (base32
                  "0brywkh2ppqqhpjhr3n6w0flf31sbmbgy6rbpdczdl1mrav44l8n"))))
      (arguments
       (substitute-keyword-arguments (package-arguments base)
         ((#:phases phases)
          #~(modify-phases #$phases
              ;; We're building with openssl included :/
              (delete 'disable-tools-libcrypto)
              (add-after 'unpack 'set-environment
                (lambda* (#:key inputs #:allow-other-keys)
                  (setenv "OPENSBI" (search-input-file inputs
                                                       "fw_dynamic.bin"))))))))
      (inputs
       (modify-inputs (package-inputs base)
         (append (specification->package "opensbi-generic")
                 (specification->package "openssl")))))))

;; This is a placeholder!!
(define install-visionfive2-u-boot
  #~(lambda (bootloader root-index image)
      (let ((spl (string-append bootloader "/libexec/spl/u-boot-spl.bin"))
            (u-boot (string-append bootloader "/libexec/u-boot.itb")))
        (write-file-on-device spl (stat:size (stat spl))
                              image (* 4096 512))
        (write-file-on-device u-boot (stat:size (stat u-boot))
                              image (* 8192 512)))))

(define u-boot-starfive-visionfive2-bootloader
  (bootloader
   (inherit u-boot-bootloader)
   (package u-boot-starfive-visionfive2)
   (disk-image-installer install-visionfive2-u-boot)))

;;

;; The kernel is based on Linus' 6.4-rc2 branch, with about 50 patches waiting
;; to be upstreamed.

(define %starfive-kernel-version "JH7110_VisionFive2_upstream")
(define %starfive-kernel-hash
  (base32 "19iqijvrsd4p9vmskl74mi2yw46kz02d6a7d1vap79gd0py3bmgq"))
(define %starfive-kernel-source
  (origin
    (method git-fetch)
    (uri (git-reference
           (url "https://github.com/starfive-tech/linux")
           (commit %starfive-kernel-version)))
    (file-name (git-file-name "linux-kernel-for-starfive" "6.4-rc2+49patches"))
    (sha256 %starfive-kernel-hash)))

(define starfive-kernel
  (let ((base ((@@ (gnu packages linux) make-linux-libre*)
               "6.4-rc2+49patches"
               "gnu"
               %starfive-kernel-source
               '("riscv64-linux")
               ;#:defconfig "visionfive_defconfig"
               ;#:defconfig "starfive_jh7100_fedora_defconfig"
               #:extra-version "starfive")))
    (package
      (inherit base)
      ;; This doesn't seem to make a difference.
      ;(source %starfive-visionfive1-kernel-source)
      )))

;; OS starts from here:

(operating-system
  (host-name "visionfive2")
  (timezone "Asia/Jerusalem")
  (locale "en_IL.utf8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))
  (keyboard-layout
    (keyboard-layout "us" "altgr-intl"))

  ;; No need for glibc-2.33.
  (locale-libcs (list (canonical-package glibc)))

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))))
  ;; not for u-boot, but for the config stuff
  ;(bootloader (bootloader-configuration
  ;              (bootloader u-boot-starfive-visionfive2-bootloader)
  ;              (targets '("/dev/mmcblk0"))))   ; SD card/eMMC (SD priority) storage
  ;; extlinux depends on syslinux
  ;(bootloader (bootloader-configuration
  ;              (bootloader extlinux-bootloader)
  ;              (targets '("/boot"))))

  (firmware '())
  ;; Plenty of options for initrd modules.
  (initrd-modules '())
  ;(initrd-modules '("dw_mmc-pltfm")) ;; suggested by Fedora? Not in 6.3-rc1+50patches kernel
  ;(initrd-modules (cons "nvme" %base-initrd-modules))
  ;(initrd-modules '("nvme"))
  ;(initrd-modules '("mmc_spi"))
  ;; https://github.com/zhaofengli/nixos-riscv64/blob/master/nixos/unmatched.nix
  ;(initrd-modules '("nvme" "mmc_block" "mmc_spi" "spi_sifive" "spi_nor"))

  ;; Try the gernic kernel first.
  ;(kernel linux-libre-riscv64-generic)
  (kernel starfive-kernel)

  ;(swap-devices
  ;  (list (swap-space
  ;          (target "/swapfile"))))

  (file-systems
    (cons* (file-system
             (device (file-system-label "root"))
             (mount-point "/")
             (type "ext4"))
           ;; We're leaving it as an efi-raw image.
           ;(file-system
           ;  (device "/dev/vda3")
           ;  ;(device (uuid "9146-2C77" 'fat32))
           ;  (mount-point "/boot/efi")
           ;  (type "vfat"))
           %guix-temproots
           %base-file-systems))

  (users (cons* (user-account
                  (name "riscv")
                  (comment "Guix RISCV User")
                  (group "users")
                  (home-directory "/home/riscv")
                  (password (crypt "starfive" "$6$abc123"))
                  (supplementary-groups
                    '("wheel" "netdev" "kvm"
                      "audio" "video")))
                %base-user-accounts))

  (packages
    (append
      (map specification->package
           (list
             ;"screen"
             ))
      %base-packages))

  (services
    (cons* (service openssh-service-type
                    (openssh-configuration
                      (openssh (specification->package "openssh-sans-x"))))

           ;(service mcron-service-type
           ;         (mcron-configuration
           ;           ;; Image created with ext4
           ;           ;(jobs (%btrfs-maintenance-jobs "/"))
           ;           (jobs
           ;             (list
           ;               #~(job '(next-hour '(3))
           ;                      "guix gc --free-space=15G")
           ;               ;; The board powers up at unix date 0.
           ;               ;; Restart ntpd to set the clock.
           ;               ;; This will run (24 hours and) 5 minutes after bootup.
           ;               ;#~(job '(next-minute-from '(next-day) '(5))
           ;               ;       "/run/current-system/profile/bin/herd restart ntpd")
           ;               ))))

           (service openntpd-service-type
                    (openntpd-configuration
                      (listen-on '("127.0.0.1" "::1"))
                      ;; Prevent moving to year 2116.
                      (constraints-from '("https://www.google.com/"))))

           ;; connman + wpa or dhcp enough?
           ;(service connman-service-type)
           ;(service wpa-supplicant-service-type)
           (service dhcp-client-service-type)

           ;(service earlyoom-service-type
           ;         (earlyoom-configuration
           ;           (prefer-regexp "(cc1(plus)?|.rustc-real|ghc|Web Content)")
           ;           (avoid-regexp "guile")))

           ;(service zram-device-service-type
           ;         (zram-device-configuration
           ;           (size (* 4 (expt 2 30)))
           ;           (compression-algorithm 'zstd)
           ;           (priority 100)))

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

;; guix system image --image-type=raw-with-offset -L ~/workspace/guix-config/ ~/workspace/guix-config/visionfive2.scm --system=riscv64-linux
