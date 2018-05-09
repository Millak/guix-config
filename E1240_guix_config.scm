(use-modules (guix store) (gnu) (gnu system nss))
(use-service-modules admin desktop mcron networking ssh)
(use-package-modules certs education fonts gnome gnuzilla kodi libreoffice linux pulseaudio)

(define %btrfs-scrub
  #~(job '(next-hour '(3))
         (string-append #$btrfs-progs "/bin/btrfs scrub start /")))

(operating-system
  (host-name "E1240")
  (timezone "Asia/Jerusalem")
  (locale "en_US.utf8")

  ;; Assuming /dev/sdX is the target hard disk, and "my-root"
  ;; is the label of the target root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-bootloader)
                (target "/dev/sdb")))

  (kernel-arguments '("zswap.enabled=1" "zram.max_pool_percent=50"
                      ;; Required to run X32 software and VMs
                      ;; https://wiki.debian.org/X32Port
                      "syscall.x32=y"))

  (file-systems (cons* (file-system
                         (device "my-root")
                         (mount-point "/")
                         (type "btrfs")
                         (title 'label)
                         (options "autodefrag,compress=lzo"))
                       (file-system
                         (device "none")
                         (mount-point "/var/guix/temproots")
                         (title 'device)
                         (type "tmpfs")
                         (check? #f))
                       %base-file-systems))

  (swap-devices '("/dev/sda1" "/dev/sdb1" "/dev/sdc1"))

  (users (cons* (user-account
                 (name "efraim")
                 (comment "Efraim")
                 (group "users")
                 (supplementary-groups '("wheel" "netdev"
                                         "audio" "video"))
                 (home-directory "/home/efraim"))
                (user-account
                 (name "rivka")
                 (comment "Rivka")
                 (group "users")
                 (supplementary-groups `("netdev"
                                         "audio" "video"))
                 (home-directory "/home/rivka"))
                (user-account
                 (name "kids")
                 (comment "both kids")
                 (group "users")
                 (supplementary-groups '("netdev"
                                         "audio" "video"))
                 (home-directory "/home/kids"))
                %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   gvfs              ;for user mounts
                   btrfs-progs pavucontrol
                   font-terminus font-dejavu
                   gcompris
                   gcompris-qt
                   kodi
                   icecat ;libreoffice
                   %base-packages))

  ;; Add GNOME and/or Xfce---we can choose at the log-in
  ;; screen with F1.  Use the "desktop" services, which
  ;; include the X11 log-in service, networking with Wicd,
  ;; and more.
  (services (cons* (xfce-desktop-service)
                   (service guix-publish-service-type
                            (guix-publish-configuration
                              (port 3000)))
                   (service openssh-service-type
                            (openssh-configuration
                              (port-number 22)
                              (allow-empty-passwords? #f)
                              (password-authentication? #t)))
                   (tor-service)
                   (service rottlog-service-type)
                   (service mcron-service-type
                            (mcron-configuration
                             (jobs (list %btrfs-scrub))))

                   (modify-services %desktop-services
                     (guix-service-type config =>
                                        (guix-configuration
                                          (inherit config)
                                          (substitute-urls
                                            (cons* ;"https://bayfront.guixsd.org"
                                                   "https://berlin.guixsd.org"
                                                   ;"http://192.168.1.134:8181" ; odroid-c2
                                                   "http://192.168.1.209:8181" ; macbook41
                                                   %default-substitute-urls))))
                     (ntp-service-type config =>
                                       (ntp-configuration
                                         (inherit config)
                                         (allow-large-adjustment? #t))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
