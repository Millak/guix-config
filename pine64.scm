(define-module (pine64))
(use-modules (guix packages)
             (gnu)
             (gnu bootloader u-boot)
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
  linux)

(operating-system
  (host-name "pine64")
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
      (bootloader u-boot-pine64-plus-bootloader)
      (targets '("/dev/mmcblk0"))))     ; SD card/eMMC (SD priority) storage

  (initrd-modules '())
  ;; The board fails to boot with stock linux-libre
  (kernel linux-libre-arm64-generic)
  (firmware '())

  (swap-devices
    (list (swap-space
            (target "/swapfile"))))

  (file-systems
    (cons* (file-system
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
  (packages
    (cons* (specification->package "nss-certs")     ; for HTTPS access
           ;(specification->package "btrfs-progs")
           ;(specification->package "compsize")
           %base-packages))

  (services
    (cons* (service openssh-service-type
                    (openssh-configuration
                      (openssh (specification->package "openssh-sans-x"))
                      (authorized-keys
                        `(("efraim" ,(local-file "Extras/efraim.pub"))))))

           (service mcron-service-type
                    (mcron-configuration
                      ;; Image created with ext4
                      ;(jobs (%btrfs-maintenance-jobs "/"))
                      (jobs
                        (list
                          #~(job '(next-hour '(3))
                                 "guix gc")
                          ;; The board powers up at unix date 0.
                          ;; Restart ntpd to set the clock.
                          ;; TODO: This job doesn't work.
                          ;#~(job "2 0 * * *"
                          ;       "herd restart ntpd")
                          ))))

           (service openntpd-service-type
                    (openntpd-configuration
                      (listen-on '("127.0.0.1" "::1"))
                      ;; Prevent moving to year 2116.
                      (constraints-from '("https://www.google.com/"))))

           (service connman-service-type)
           (service wpa-supplicant-service-type)

           (service earlyoom-service-type
                    (earlyoom-configuration
                      (prefer-regexp "(cc1(plus)?|.rustc-real|ghc|Web Content)")
                      (avoid-regexp "guile")))

           (service zram-device-service-type
                    (zram-device-configuration
                      (size (* 2 (expt 2 30)))
                      (compression-algorithm 'zstd)
                      (priority 100)))

           (modify-services
             %base-services
             (guix-service-type
               config =>
               (guix-configuration
                 (inherit config)
                 (discover? #t)
                 (substitute-urls %substitute-urls)
                 (authorized-keys %authorized-keys)
                 (extra-options
                   (cons* "--cores=2" "--cache-failures" %extra-options)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))

;; guix system image --image-type=pine64-raw -L ~/workspace/guix-config/ ~/workspace/guix-config/pine64.scm --system=aarch64-linux
