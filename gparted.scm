;; This is an operating system configuration for a bootable GParted image.
;; Modify it as you see fit and rebuild it by running:
;;
;;   guix system image /path/to/gparted.scm
;;

(define-module (gparted))
(use-modules (gnu)
             (guix)
             (srfi srfi-1)
             (guix build-system trivial))
(use-service-modules
  admin
  xorg)
(use-package-modules
  disk
  gtk
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

(define gtk+-minimal
  (package
    (inherit gtk+)
    (arguments
     (substitute-keyword-arguments (package-arguments gtk+)
       ;; The tests need more of the inputs that we've stripped
       ;; away in order to pass. Skip the tests for now.
       ((#:tests? _ #t) #f)
       ((#:configure-flags _ ''())
        `(list "--disable-cups"
               "--disable-introspection"
               "--enable-x11-backend"
               "--disable-gtk-doc-html"))))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs gtk+)
                    (prepend gdk-pixbuf)
                    (delete "fontconfig"
                            "freetype"
                            "librsvg"   ; gdk-pixbuf
                            "libcloudproviders-minimal"
                            "libx11"
                            "libxcomposite"
                            "libxcursor"
                            "libxdamage"
                            "libxext"
                            "libxfixes"
                            "libxinerama"
                            "libxkbcommon"
                            "libxrandr"
                            "libxrender"
                            "mesa"
                            "wayland"
                            "wayland-protocols")))
    (inputs
     (modify-inputs (package-inputs gtk+)
                    (delete "colord-minimal"
                            "cups"
                            "graphene"
                            "harfbuzz")))))

(define harfbuzz-minimal
  (package
    (inherit harfbuzz)
    (arguments
     (substitute-keyword-arguments (package-arguments harfbuzz)
       ((#:configure-flags cf ''())
        `(cons* "--with-icu=no"
                (delete "--with-graphite2" ,cf)))))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs harfbuzz)
                    (delete "graphite2" "icu4c")))))

(define use-minimal-gtk+
  (package-input-rewriting/spec
    `(("gtk+" . ,(const gtk+-minimal))
      ("harfbuzz" . ,(const harfbuzz-minimal)))))

(define gparted-custom
  (package
    (inherit (use-minimal-gtk+ gparted))))

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
                           "adwaita-icon-theme" ; guix-gc--references -> nothing
                           "neofetch"           ; bash-minimal
                           ;"nss-certs"         ; Actually not sure why we'd need this.

                           ;"gparted"            ; all the things!
                           "xterm"              ; actually, a lot

                           "cryptsetup"         ; libgcrypt, util-linux:lib, eudev, json-c, argon2, libgpg-error, popt, lvm2
                           ;"cryptsetup-static"  ; guix-gc--references -> nothing
                           "lvm2"               ; lvm2-static has a larger size than lvm2 with the same closure
                           "mdadm"              ; eudev
                           ;"mdadm-static"       ; guix-gc--references -> nothing

                           ;"bcachefs-tools-static"
                           "btrfs-progs"        ; zstd:lib, e2fsprogs, eudev, zlib, lzo
                           ;"btrfs-progs-static" ; guix-gc--references -> nothing
                           "dosfstools"         ; only glibc, gcc:lib
                           "mtools"             ; needed by fat16/fat32; glibc, gcc:lib, bash-minimal
                           "e2fsprogs"          ; util-linux:lib
                           "exfatprogs"         ; only glibc, gcc:lib
                           "f2fs-tools"         ; util-linux:lib
                           "jfsutils"           ; util-linux:lib
                           "nilfs-utils"        ; util-linux:lib
                           "ntfs-3g"            ; fuse-2
                           ;"ntfs-3g-static"     ; only glibc
                           "udftools"           ; only glibc, gcc:lib
                           "xfsprogs"))
                    (list gparted-custom
                          fluxbox-custom)       ; also a lot :/
                    %base-packages))

  ;; Use a modified list of setuid-programs.
  ;; Are there any we need? We run as root.
  (setuid-programs
    (list
  ;    (setuid-program (program (file-append foo "/bin/foo")))
    ))

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
                          "exec /run/current-system/profile/bin/gparted &\n"
                          "exec /run/current-system/profile/bin/xterm &\n"
                          "exec fluxbox\n")))))

     (remove (lambda (service)
               (let ((type (service-kind service)))
                 (memq type
                       (list
                         guix-service-type          ; not actually needed?
                         log-cleanup-service-type
                         nscd-service-type          ; no networking
                         rottlog-service-type))))
             (modify-services
               %base-services
               (udev-service-type
                 config =>
                 (udev-configuration
                   (rules (list lvm2 fuse mdadm))))))))

  ;; Allow resolution of '.local' host names with mDNS.
  ;; No network!
  ;(name-service-switch %mdns-host-lookup-nss)
  )
