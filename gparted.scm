;; This is an operating system configuration for a bootable GParted image.
;; Modify it as you see fit and rebuild it by running:
;;
;;   guix system image /path/to/gparted.scm
;;

(use-modules (gnu) (guix) (srfi srfi-1))
(use-service-modules desktop networking xorg)
(use-package-modules
  admin
  bootloaders
  certs
  disk
  gnome
  linux
  package-management
  wm
  xorg)

(operating-system
  (host-name "gnu")
  (timezone "Etc/UTC")
  (locale "en_US.utf8")
  (keyboard-layout (keyboard-layout "us" "altgr-intl"))

  ;; Label for the GRUB boot menu.
  (label (string-append "GNU Guix " (package-version guix) " with GParted"))

  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (target "/dev/sda")
               (terminal-outputs '(console))))
  (file-systems (cons (file-system
                        (mount-point "/")
                        (device "/dev/sda1")
                        (type "ext4"))
                      %base-file-systems))

  (users %base-user-accounts)

  (packages (append (list
                      adwaita-icon-theme
                      lvm2
                      neofetch
                      nss-certs
                      fluxbox)
                    %base-packages-disk-utilities
                    %base-packages))

  (services
   (append (list (service slim-service-type
                          (slim-configuration
                            (auto-login? #t)
                            (default-user "root")
                            (xorg-configuration
                              (xorg-configuration
                                (keyboard-layout keyboard-layout)))))

                 (service special-files-service-type
                          `(("/root/.fluxbox/startup"
                             ,(mixed-text-file "fluxbox-startup"
                                               "exec " gparted "/bin/gparted &\n"
                                               "exec " xterm "/bin/xterm &\n"
                                               "exec fluxbox\n")))))

           (remove (lambda (service)
                     (let ((type (service-kind service)))
                       (or (memq type
                                 (list gdm-service-type
                                       cups-pk-helper-service-type
                                       modem-manager-service-type))
                           (eq? 'network-manager-applet
                                (service-type-name type)))))
                   %desktop-services)))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
