;; This is an operating system configuration generated
;; by the graphical installer.

(use-modules (gnu))
(use-service-modules desktop networking ssh xorg)

(operating-system
  (locale "en_IL.utf8")
  (timezone "Asia/Jerusalem")
  (keyboard-layout
    (keyboard-layout "us" "altgr-intl"))
  (host-name "3900XT")
  (users (cons* (user-account
                  (name "efraim")
                  (comment "Efraim Flashner")
                  (group "users")
                  (home-directory "/home/efraim")
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))
  (packages
    (append
      (list (specification->package "nss-certs"))
      %base-packages))
  (services
    (append
      (list (service enlightenment-desktop-service-type)
            (service openssh-service-type)
            (service tor-service-type)
            (set-xorg-configuration
              (xorg-configuration
                (keyboard-layout keyboard-layout))))
      %desktop-services))
  (bootloader
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (target "/boot/efi")
      (keyboard-layout keyboard-layout)))
  (file-systems
    (cons* (file-system
             (mount-point "/")
             (device
               (uuid "20048579-a0bd-4180-8ea3-4b546309fb3b"
                     'btrfs))
             (type "btrfs"))
           (file-system
             (mount-point "/boot/efi")
             (device (uuid "9146-2C77" 'fat32))
             (type "vfat"))
           %base-file-systems)))
