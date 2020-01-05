(use-modules (guix store)
             (guix gexp)
             (gnu)
             (gnu system locale)
             (config os-release)
             (srfi srfi-1))
(use-service-modules admin cups desktop mcron networking security-token ssh virtualization xorg)
(use-package-modules certs connman cups linux scanner video virtualization xorg)

(define %btrfs-scrub
  #~(job '(next-hour '(3))
         (string-append #$btrfs-progs "/bin/btrfs scrub start -c 3 /")))

(define %btrfs-balance
  #~(job '(next-hour '(5))
         (string-append #$btrfs-progs "/bin/btrfs balance start -dusage=50 -musage=70 /")))

(define %my-xorg-modules
  ;; Only the modules on this laptop
  ;; It must be an explicit list, 'fold delete %default-xorg-modules' isn't enough.
  (list xf86-video-vesa
        xf86-video-fbdev
        xf86-video-intel
        xf86-input-libinput))

(define %my-macbook-touchpad
  "Section \"InputClass\"
      Identifier \"touchpad catchall\"
      Driver \"libinput\"
      MatchIsTouchpad \"on\"
      Option \"ClickMethod\" \"clickfinger\"
      Option \"TappingButtonMap\" \"lrm\"
  EndSection")

(operating-system
  (host-name "macbook41")
  (timezone "Asia/Jerusalem")
  (locale "en_US.UTF-8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))

  ;; Assuming /dev/sdX is the target hard disk, and "my-root"
  ;; is the label of the target root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (target "/boot/efi")))

  (kernel-arguments '("zswap.enabled=1"
                      "zswap.compressor=lz4"
                      "zswap.zpool=z3fold"
                      ;; Required to run X32 software and VMs
                      ;; https://wiki.debian.org/X32Port
                      ;; Still untested on GuixSD.
                      "syscall.x32=y"))

  (file-systems (cons* (file-system
                         (device (file-system-label "my-root"))
                         (mount-point "/")
                         (type "btrfs")
                         (options "autodefrag,compress=lzo,discard,ssd_spread"))
                       (file-system
                         (device "tmpfs")
                         (mount-point "/var/guix/temproots")
                         (type "tmpfs")
                         (check? #f))
                       ;; This directory shouldn't exist
                       (file-system
                         (device "none")
                         (mount-point "/var/cache/fontconfig")
                         (type "tmpfs")
                         (flags '(read-only))
                         (check? #f))
                       (file-system
                         (device (uuid "F010-1913" 'fat))
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
                                        "libvirt"
                                        "audio" "video"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  ;; This is where we specify system-wide packages.
  (packages (cons* nss-certs         ;for HTTPS access
                   cups
                   econnman
                   btrfs-progs compsize
                   virt-manager
                   libvdpau-va-gl    ;intel graphics vdpau
                   intel-vaapi-driver
                   %base-packages))

  (services (cons* (service enlightenment-desktop-service-type)

                   (simple-service 'os-release etc-service-type
                                   `(("os-release" ,%os-release-file)))

                   (service guix-publish-service-type
                            (guix-publish-configuration
                              (host "0.0.0.0")
                              (port 3000)))
                   (service openssh-service-type
                            (openssh-configuration
                              (password-authentication? #t)))

                   (service tor-service-type)
                   (tor-hidden-service "ssh"
                                       '((22 "127.0.0.1:22")))
                   (tor-hidden-service "guix-publish"
                                       ; ql3bdn6vkhhwdcj5.onion
                                       '((3000 "127.0.0.1:3000")))

                   (service cups-service-type
                            (cups-configuration
                              (web-interface? #t)
                              (default-paper-size "A4")
                              (extensions
                                (list cups-filters hplip-minimal))))
                   (simple-service 'custom-udev-rules udev-service-type
                                   (list sane-backends-minimal))

                   (service rottlog-service-type)
                   (service mcron-service-type
                            (mcron-configuration
                             (jobs (list %btrfs-scrub
                                         %btrfs-balance))))

                   (service openntpd-service-type
                            (openntpd-configuration
                              (listen-on '("127.0.0.1" "::1"))
                              (allow-large-adjustment? #t)))

                   (service connman-service-type)

                   (service libvirt-service-type
                            (libvirt-configuration
                              (unix-sock-group "libvirt")))
                   (service virtlog-service-type)

                   (service pcscd-service-type)

                   (service slim-service-type
                            (slim-configuration
                              (xorg-configuration
                                (xorg-configuration
                                  (extra-config (list %my-macbook-touchpad))
                                  (modules %my-xorg-modules)))))

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
                                 (substitute-urls
                                   (list "http://192.168.1.183:3000" ; E2140
                                         "http://192.168.1.217:3000" ; E5400
                                         "https://ci.guix.gnu.org"
                                         "https://bayfront.guixsd.org"
                                         "http://guix.genenetwork.org"
                                         "https://guix.tobias.gr"))
                                 (authorized-keys
                                   (list (local-file "Extras/E2140_publish.pub")
                                         (local-file "Extras/E5400_publish.pub")
                                         (local-file "Extras/ci.guix.gnu.org.pub")
                                         (local-file "Extras/guix.genenetwork.org.pub")
                                         (local-file "Extras/guix.tobias.gr.pub")))
                                 (extra-options
                                   (list "--gc-keep-derivations=yes"
                                         "--gc-keep-outputs=yes"
                                         "--cores=1")))))))) ; we're on a laptop

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
