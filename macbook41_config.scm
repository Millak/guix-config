(use-modules (guix store)
             (gnu)
             (gnu system locale)
             (srfi srfi-1))
(use-service-modules admin cups desktop mcron networking pm security-token ssh virtualization xorg)
(use-package-modules certs connman cups linux video virtualization xorg)

(define %btrfs-scrub
  #~(job '(next-hour '(3))
         (string-append #$btrfs-progs "/bin/btrfs scrub start -c 3 /")))

(define %btrfs-balance
  #~(job '(next-hour '(5))
         (string-append #$btrfs-progs "/bin/btrfs balance start -dusage=50 -musage=70 /")))

(define %os-release-file
  (plain-file "os-release"
              (string-append
                "NAME=\"GNU Guix\"\n"
                "PRETTY_NAME=\"GNU Guix\"\n"
                "VERSION=\""((@ (guix packages) package-version) (@ (gnu packages package-management) guix))"\"\n"
                "ID=guix\n"
                "HOME_URL=\"https://www.gnu.org/software/guix/\"\n"
                "SUPPORT_URL=\"https://www.gnu.org/software/guix/help/\"\n"
                "BUG_REPORT_URL=\"mailto:bug-guix@gnu.org\"\n")))

(define %my-xorg-modules
  ;; Only the modules on this laptop
  ;; It must be an explicit list, 'fold delete %default-xorg-modules' isn't enough.
  (list xf86-video-vesa
        xf86-video-fbdev
        xf86-video-intel
        xf86-input-libinput))

;; This is untested!
;; https://blog.jessfraz.com/post/linux-on-mac/
(define my-macbook-touchpad
  "Section \"InputClass\"
      Identifier \"touchpad catchall\"
      Driver \"synaptics\"
      MatchIsTouchpad \"on\"
  EndSection")

(define (remove-services types services)
  (remove (lambda (service)
            (any (lambda (type)
                   (eq? (service-kind service) type))
                 types))
          services))

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
                      ;; Still untested on GuixSD.
                      "syscall.x32=y"))

  (file-systems (cons* (file-system
                         (device (file-system-label "my-root"))
                         (mount-point "/")
                         (type "btrfs")
                         (options "autodefrag,compress=lzo,discard,ssd_spread"))
                       (file-system
                         (device "none")
                         (mount-point "/var/guix/temproots")
                         (type "tmpfs")
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
                   btrfs-progs
                   virt-manager
                   libvdpau-va-gl    ;intel graphics vdpau
                   %base-packages))

  (services (cons* (service enlightenment-desktop-service-type)

                   (service special-files-service-type
                            `(("/etc/os-release" ,%os-release-file)))

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

                   (service tlp-service-type)

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

                   (modify-services (remove-services
                                      (list
                                        ntp-service-type
                                        screen-locker-service-type
                                        network-manager-service-type)
                                      %desktop-services)
                     (guix-service-type config =>
                                        (guix-configuration
                                          (inherit config)
                                          (substitute-urls
                                            (list "http://192.168.1.183:3000" ; E2140
                                                  "http://firefly.lan:8181"
                                                  "https://ci.guix.info"
                                                  "https://bayfront.guixsd.org"
                                                  "https://mirror.hydra.gnu.org"))
                                          (authorized-keys
                                            (list (local-file "Extras/ci.guix.info.pub")
                                                  (local-file "Extras/hydra.gnu.org.pub")
                                                  (local-file "Extras/firefly_publish.pub")
                                                  (local-file "Extras/E2140_publish.pub")))
                                          (extra-options
                                            (list "--gc-keep-derivations=yes"
                                                  "--gc-keep-outputs=yes"
                                                  "--cores=1")))) ; we're on a laptop

                     (slim-service-type config =>
                                        (slim-configuration
                                          (inherit config)
                                          (xorg-configuration
                                            (xorg-configuration
                                              (modules %my-xorg-modules))))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
