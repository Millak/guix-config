;; This is an operating system configuration for a bootable GParted image.
;; Modify it as you see fit and rebuild it by running:
;;
;;   guix system image /path/to/gparted.scm
;;

(define-module (gparted))
(use-modules (gnu)
             (guix)
             (guix transformations)
             (srfi srfi-1)
             (guix build-system trivial))
(use-service-modules
  admin
  xorg)
(use-package-modules
  compression
  disk
  fontutils
  gl
  gtk
  linux
  llvm
  package-management
  wm
  xorg)

;;

(define gtk+-minimal
  (package/inherit gtk+
    (arguments
     (substitute-keyword-arguments (package-arguments gtk+)
       ;; The tests need more of the inputs that we've stripped
       ;; away in order to pass. Skip the tests for now.
       ((#:tests? _ #t) #f)
       ((#:configure-flags _ ''())
        `(list "--disable-cups"
               "--disable-introspection"
               "--enable-x11-backend"
               "--disable-gtk-doc-html"
               (string-append "--with-html-dir="
                              (assoc-ref %outputs "doc")
                              "/share/gtk-doc/html")))
       ((#:phases phases)
        `(modify-phases ,phases
           (add-after 'install 'remove-localizations
             (lambda* (#:key outputs #:allow-other-keys)
               (delete-file-recursively
                 (string-append (assoc-ref outputs "out")
                                "/share/locale"))))))))
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
                            "iso-codes"
                            "harfbuzz")))))

(define harfbuzz-minimal
  (package/inherit harfbuzz
    (outputs (cons "doc" (package-outputs harfbuzz)))
    (arguments
     (substitute-keyword-arguments (package-arguments harfbuzz)
       ((#:configure-flags cf ''())
        `(cons* "--with-icu=no"
                ;"--disable-introspection"  ; causes pango to fail
                "--disable-gtk-doc-html"
                (string-append "--with-html-dir="
                               (assoc-ref %outputs "doc")
                               "/share/gtk-doc/html")
                (delete "--with-graphite2" ,cf)))))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs harfbuzz)
                    (delete "graphite2" "icu4c")))))

;; freetype-config embeds a reference to pkg-config.
(define freetype-minimal
  (package
    (inherit freetype)
    (arguments
     (substitute-keyword-arguments (package-arguments freetype)
       ((#:configure-flags _)
        ;`(list "--disable-static"))))))
        `(list "--disable-freetype-config"))))))

(define util-linux-minimal
  (package/inherit util-linux
    (arguments
     (substitute-keyword-arguments (package-arguments util-linux)
       ((#:phases phases '%standard-phases)
        `(modify-phases ,phases
           (add-after 'install 'remove-localizations
             (lambda* (#:key outputs #:allow-other-keys)
               (delete-file-recursively
                 ;; ~75% of the "lib" output.
                 (string-append (assoc-ref outputs "lib")
                                "/share/locale"))))))))))

(define (remove-static-libraries pkg)
  (package/inherit pkg
    ;(name (string-append (package-name pkg) "-smaller"))
    (arguments
     (substitute-keyword-arguments (package-arguments pkg)
       ((#:phases phases '%standard-phases)
        `(modify-phases ,phases
           (add-after 'install 'delete-static-libraries
             (lambda* (#:key outputs #:allow-other-keys)
               (for-each delete-file
                         (find-files
                           (string-append (assoc-ref outputs "out") "/lib")
                           "\\.a$"))))))))))

(define libelf-smaller
  (remove-static-libraries (specification->package "libelf")))

(define elfutils-smaller
  (remove-static-libraries (specification->package "elfutils")))

(define ncurses-smaller
  (remove-static-libraries (specification->package "ncurses")))

(define readline-smaller
  (remove-static-libraries (specification->package "readline")))

(define parted-minimal
  (package
    (inherit parted)
    (arguments
     (substitute-keyword-arguments (package-arguments parted)
       ((#:configure-flags cf ''())
        `(cons* "--without-readline"
                "--disable-static"
                ,cf))))
    (inputs (modify-inputs (package-inputs parted)
                           (delete "readline")))))

(define mesa-smaller
  (package/inherit mesa
    (arguments
     (substitute-keyword-arguments (package-arguments mesa)
       ((#:modules modules)
        `((ice-9 regex)
          (srfi srfi-26)
          ,@modules))
       ((#:build-type _) "minsize") ; decreases the size by ~30%.
       ((#:configure-flags cf ''())
        `(append
           (remove
             (cut string-match
                  "-D(platforms|vulkan-(drivers|layers)|gles2|gbm|shared-glapi)=.*" <>)
             ,cf)

           ;; This has to go last so we can disable vulkan.
           (list "-Dplatforms=x11"
                 "-Dvulkan-drivers=")))))
    (inputs
     (modify-inputs (package-inputs mesa)
                    (prepend (list zstd "lib"))
                    ;; TODO: Can this be taken care of with use-minimized-inputs?
                    (replace "llvm" llvm-minimal)
                    (delete "wayland" "wayland-protocols")))))

;; We could use a newer version of llvm, but this is the version mesa
;; is currently built against, so it has the most testing in Guix.
(define llvm-minimal
  (package/inherit llvm-11
    ;; If we can separate out the include directory we'd save another 21MB.
    (outputs (list "out"))
    (version (package-version llvm-11))
    (arguments
     (substitute-keyword-arguments (package-arguments llvm-11)
       ((#:build-type _) "MinSizeRel") ; decreases the size by ~25%
       ((#:configure-flags cf ''())
        ;; AMDGPU is needed by the vulkan drivers.
        `(list ,(string-append "-DLLVM_TARGETS_TO_BUILD="
                                (system->llvm-target) ";AMDGPU")
               "-DLLVM_BUILD_TOOLS=NO"
               "-DLLVM_BUILD_LLVM_DYLIB=YES"
               "-DLLVM_LINK_LLVM_DYLIB=YES"))
       ((#:phases phases)
        `(modify-phases ,phases
           (add-after 'install 'delete-static-libraries
             (lambda* (#:key outputs #:allow-other-keys)
               (for-each delete-file
                         (find-files (string-append
                                       (assoc-ref outputs "out") "/lib")
                                     "\\.a$"))))
           (replace 'install-opt-viewer
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((out (assoc-ref outputs "out")))
                 (delete-file-recursively
                   (string-append out "/share/opt-viewer")))))
           (add-after 'install 'build-and-install-llvm-config
             (lambda* (#:key outputs #:allow-other-keys)
               (let ((out (assoc-ref outputs "out")))
                 (substitute*
                   "tools/llvm-config/CMakeFiles/llvm-config.dir/link.txt"
                   (((string-append "/tmp/guix-build-llvm-"
                                    ,version ".drv-0/build/lib"))
                    (string-append out "/lib")))
                 (invoke "make" "llvm-config")
                 (install-file "bin/llvm-config"
                               (string-append out "/bin")))))))))))

(define use-minimized-inputs
  (package-input-rewriting/spec
    `(;("freetype" . ,(const freetype-minimal)) ; breaks python!?
      ("gtk+" . ,(const gtk+-minimal))
      ("harfbuzz" . ,(const harfbuzz-minimal))
      ("llvm" . ,(const llvm-minimal))
      ("mesa" . ,(const mesa-smaller))
      ("parted" . ,(const parted-minimal))
      ;; These cause many rebuilds. Use a graft?
      ("elfutils" . ,(const elfutils-smaller))
      ;("libelf" . ,(const libelf-smaller))     ; breaks glib?
      ;("ncurses" . ,(const ncurses-smaller))   ; breaks procpcs
      ;("readline" . ,(const readline-smaller)) ; many rebuilds
      ;("util-linux" . ,(const util-linux-minimal))  ; breaks python?
      )))

;;

;; This needs to be rebuilt, not just substituted.
(define fluxbox-custom
  (let ((base (use-minimized-inputs fluxbox)))
    (package/inherit base
      (arguments
       (substitute-keyword-arguments (package-arguments base)
         ((#:phases phases)
          `(modify-phases ,phases
             (delete 'install-vim-files)
             (add-after 'install 'adjust-fluxbox-menu
               (lambda* (#:key outputs #:allow-other-keys)
                (let ((out (assoc-ref %outputs "out")))
                  (substitute* (string-append out "/share/fluxbox/menu")
                    (("\\(firefox.*") "(gparted) {gparted}\n"))))))))))))

(define gparted-custom
  (package
    (inherit (use-minimized-inputs gparted))
    (arguments
     (substitute-keyword-arguments (package-arguments gparted)
       ((#:configure-flags cf ''())
        `(cons* "--enable-libparted-dmraid" ,cf))))))

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
  (firmware '())

  (users %base-user-accounts)

  (packages (append (map specification->package
                         (list
                           "neofetch"           ; bash-minimal

                           "xterm"              ; actually, a lot

                           "cryptsetup"         ; libgcrypt, util-linux:lib, eudev, json-c, argon2, libgpg-error, popt, lvm2
                           "lvm2"               ; lvm2-static has a larger size than lvm2 with the same closure
                           "mdadm"              ; eudev

                           ;"bcachefs-tools"
                           "btrfs-progs"        ; zstd:lib, e2fsprogs, eudev, zlib, lzo
                           "dosfstools"         ; only glibc, gcc:lib
                           "mtools"             ; needed by fat16/fat32; glibc, gcc:lib, bash-minimal
                           "e2fsprogs"          ; util-linux:lib
                           "exfatprogs"         ; only glibc, gcc:lib
                           "f2fs-tools"         ; util-linux:lib
                           "jfsutils"           ; util-linux:lib
                           "nilfs-utils"        ; util-linux:lib
                           "ntfs-3g"            ; fuse-2
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
                         guix-service-type          ; not actually needed
                         log-cleanup-service-type
                         nscd-service-type          ; no networking
                         rottlog-service-type))))
             (modify-services
               %base-services
               (udev-service-type
                 config =>
                 (udev-configuration
                   (rules (list lvm2 fuse mdadm)))))))))
