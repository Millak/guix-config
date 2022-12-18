;; This is an operating system configuration for a bootable GParted image.
;; Modify it as you see fit and rebuild it by running:
;;
;;   guix system image /path/to/gparted.scm
;;

(define-module (gparted))
(use-modules (gnu) (guix) (srfi srfi-1) (guix build-system trivial) (dfsg main nilfs))
(use-service-modules
  admin
  xorg)
(use-package-modules
  linux
  package-management
  wm
  xorg)

;;

(define fluxbox-custom
  (package
    (name "fluxbox-custom")
    (version (package-version fluxbox))
    (source #f)
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin (use-modules (guix build utils))
              (let* ((source (assoc-ref %build-inputs "fluxbox"))
                     (out    (assoc-ref %outputs "out")))
                (copy-recursively source out)
                (substitute* (string-append out "/share/fluxbox/menu")
                  (("\\(firefox.*") "(gparted) {gparted}\n"))))))
    (native-inputs (list fluxbox))
    (home-page (package-home-page fluxbox))
    (synopsis (package-synopsis fluxbox))
    (description (package-description fluxbox))
    (license (package-license fluxbox))))

;;

(operating-system
  (host-name "gnu")
  (timezone "Etc/UTC")
  (locale "en_US.utf8")
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))

  ;; Label for the GRUB boot menu.
  (label (string-append "GNU Guix " (package-version guix) " with GParted"))

  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (targets '("/dev/sda"))
               (terminal-outputs '(console))))
  (file-systems (cons (file-system
                        (mount-point "/")
                        (device "/dev/sda1")
                        (type "ext4"))
                      %base-file-systems))

  (users %base-user-accounts)

  (packages (append (map specification->package
                         (list
                           "adwaita-icon-theme"
                           "neofetch"
                           "nss-certs"

                           "gparted"
                           "xterm"

                           "cryptsetup"
                           "lvm2"
                           "mdadm"

                           "btrfs-progs"
                           "dosfstools"
                           "e2fsprogs"
                           "exfatprogs"
                           "f2fs-tools"
                           "jfsutils"
                           "nilfs-utils"
                           "ntfs-3g"
                           "udftools"
                           "xfsprogs"))
                    (list fluxbox-custom)
                    %base-packages))

  (services
   (append
     (list (service slim-service-type
                    (slim-configuration
                      (auto-login? #t)
                      (default-user "root")
                      (xorg-configuration
                        (xorg-configuration
                          (keyboard-layout keyboard-layout)))))

           (service special-files-service-type
                    `(("/root/.fluxbox/startup"
                       ,(mixed-text-file
                          "fluxbox-startup"
                          "exec " (specification->package "gparted") "/bin/gparted &\n"
                          "exec " (specification->package "xterm") "/bin/xterm &\n"
                          "exec fluxbox\n")))))

     (remove (lambda (service)
               (let ((type (service-kind service)))
                 (memq type
                       (list
                         log-cleanup-service-type
                         rottlog-service-type))))
             (modify-services
               %base-services
               (udev-service-type
                 config =>
                 (udev-configuration
                   (rules (list lvm2 fuse))))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
