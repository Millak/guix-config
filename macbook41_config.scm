(use-modules (guix store) (gnu) (gnu system nss) (gnu system locale))
(use-service-modules admin cups desktop mcron networking pm ssh xorg)
(use-package-modules bootloaders certs cups gnome linux video)

(define %btrfs-scrub
  #~(job '(next-hour '(3))
         (string-append #$btrfs-progs "/bin/btrfs scrub -c 3 start /")))

(define %btrfs-balance
  #~(job '(next-hour '(5))
         (string-append #$btrfs-progs "/bin/btrfs balance start -dusage 50 -musage 70 /")))

(operating-system
  (host-name "macbook41")
  (timezone "Asia/Jerusalem")
  (locale "en_US.utf8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.utf8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.utf8"))))

  ;; Assuming /dev/sdX is the target hard disk, and "my-root"
  ;; is the label of the target root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (target "/boot/efi")))

  (kernel-arguments '("zswap.enabled=1"
                      ;; Required to run X32 software and VMs
                      ;; https://wiki.debian.org/X32Port
                      "syscall.x32=y"))

  (file-systems (cons* (file-system
                         (device "my-root")
                         (mount-point "/")
                         (type "btrfs")
                         (title 'label)
                         (options "autodefrag,compress=lzo,discard,ssd_spread"))
                       (file-system
                         (device "none")
                         (mount-point "/var/guix/temproots")
                         (title 'device)
                         (type "tmpfs")
                         (check? #f))
                       (file-system
                         (device (uuid "F010-1913" 'fat))
                         (title 'uuid)
                         (mount-point "/boot/efi")
                         (type "vfat"))
                       %base-file-systems))

  (swap-devices '("/dev/sda2"))

  (users (cons (user-account
                (name "efraim")
                (comment "Efraim")
                (group "users")
                (supplementary-groups '("wheel" "netdev" "kvm"
                                        "lp" "lpadmin"
                                        "audio" "video"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   gvfs              ;for user mounts
                   cups
                   btrfs-progs
                   libvdpau-va-gl    ;intel graphics vdpau
                   %base-packages))

  (services (cons* (service enlightenment-desktop-service-type)
                   (console-keymap-service "il-heb")
                   (service guix-publish-service-type
                            (guix-publish-configuration
                              (port 3000)))
                   (service openssh-service-type
                            (openssh-configuration
                              (port-number 22)
                              (allow-empty-passwords? #f)
                              (password-authentication? #t)))
                   (tor-service)

                   (service cups-service-type
                            (cups-configuration
                              (web-interface? #t)
                              (extensions
                                (list cups-filters hplip))))

                   (service tlp-service-type)

                   (service rottlog-service-type)
                   (service mcron-service-type
                            (mcron-configuration
                             (jobs (list %btrfs-scrub
                                         %btrfs-balance))))

                   (modify-services %desktop-services
                     (guix-service-type config =>
                                        (guix-configuration
                                          (inherit config)
                                          (substitute-urls
                                            (cons* ;"https://bayfront.guixsd.org" ; currently offline
                                                   "https://berlin.guixsd.org"
                                                   ;"http://192.168.1.134:8181" ; odroid-c2
                                                   "http://192.168.1.183" ; E1240
                                                   %default-substitute-urls))
                                          (extra-options
                                            '("--cores=1")))) ; we're on a laptop

                     (ntp-service-type config =>
                                       (ntp-configuration
                                         (inherit config)
                                         (allow-large-adjustment? #t))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
