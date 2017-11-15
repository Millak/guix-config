(use-modules (guix store) (gnu) (gnu system nss))
(use-service-modules desktop mcron networking pm ssh)
(use-package-modules bootloaders certs gnome libreoffice linux)

(define %btrfs-scrub
  #~(job '(next-hour '(3))
         (string-append #:btrfs-progs-static "/bin/btrfs scrub start /")))

(operating-system
  (host-name "macbook41")
  (timezone "Asia/Jerusalem")
  (locale "en_US.utf8")

  ;; Assuming /dev/sdX is the target hard disk, and "my-root"
  ;; is the label of the target root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (target "/boot/efi")))

  (kernel-arguments '("zswap.enabled=1"))

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
                       (file-system
                         (device "/dev/sda1")
                         (mount-point "/boot/efi")
                         (type "vfat"))
                       %base-file-systems))

  (swap-devices '("/dev/sda2"))

  (users (cons (user-account
                (name "efraim")
                (comment "Efraim")
                (group "users")
                (supplementary-groups '("wheel" "netdev" "kvm"
                                        "audio" "video"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   gvfs              ;for user mounts
                   btrfs-progs
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

                   (service tlp-service-type)
                   (service thermald-service-type)

                   (service mcron-service-type
                            (mcron-configuration
                             (jobs (list %btrfs-scrub))))

                   (modify-services %desktop-services
                     (guix-service-type config =>
                                        (guix-configuration
                                          (inherit config)
                                          (substitute-urls
                                            (cons* "https://bayfront.guixsd.org"
                                                   "https://berlin.guixsd.org"
                                                   "http://192.168.1.134:8181" ; odroid-c2
                                                   "http://192.168.1.183" ; E1240
                                                   %default-substitute-urls))))
                     (ntp-service-type config =>
                                       (ntp-configuration
                                         (inherit config)
                                         (allow-large-adjustment? #t))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
