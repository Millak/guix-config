(define-module (Guix_manifest))
(use-modules (guix profiles)
             (guix transformations)
             (guix packages)
             (guix utils)
             (gnu packages)
             (ice-9 match)
             (srfi srfi-1))

;; Define a couple of our own architecture groupings depending on which architectures support various features
(define* (with-rust? #:optional (system (or (%current-target-system)
                                            (%current-system))))
         (target-x86-64? target))

(define* (with-ghc? #:optional (system (or (%current-target-system)
                                           (%current-system))))
         (target-x86? target))

(define* (with-go? #:optional (system (or (%current-target-system)
                                          (%current-system))))
         (not (or (target-ppc32? target)
                  (target-riscv64? target))))


(define headless?
  (eq? #f (getenv "DISPLAY")))

(define UTenn_machines
  (list "lily"
        "octopus01"
        "penguin2"
        "space"
        "tux01"
        "tux02"
        "tux03"))

(define guix-system
  (file-exists? "/run/current-system/provenance"))

(define work-machine?
  (not (eq? #f (member (gethostname)
                       (cons "bayfront"
                             UTenn_machines)))))

(define %GUI-only
  (list "adwaita-icon-theme"
        "ephoto"
        "evisum"
        "font-culmus"
        "font-dejavu"
        "font-ghostscript"
        "font-gnu-freefont"
        "font-gnu-unifont"
        "font-opendyslexic"
        "font-terminus"
        "flatpak"
        "gst-plugins-good"
        "gst-plugins-ugly"
        "icecat"
        "kdeconnect"
        "keepassxc"
        "lagrange"
        "libnotify"     ; notify-send
        "libreoffice"
        "mpv"
        "mpv-mpris"
        "mupdf"
        "my-moreutils"
        "netsurf"
        "nheko"
        "pavucontrol"
        "pinentry-efl"
        "qtwayland"
        "quasselclient"
        "qutebrowser"
        "terminology"
        "viewnior"
        "wl-clipboard-x11"
        "zathura"
        "zathura-pdf-poppler"))

(define %work-applications
  (list ;"diffoscope"
        "mercurial"
        "strace"))

(define %not-for-work
  (list "btrfs-progs"
        "catimg"
        "ffmpeg"
        "isync"
        "keybase"
        "khal"
        "khard"
        "libhdate"
        "msmtp"
        "mutt"
        "parcimonie"
        "sshfs"
        "syncthing"
        "toot"
        "vdirsyncer"
        "weechat"
        "yt-dlp"))

(define %not-for-work-ghc
  (list "git-annex"))

(define %not-for-work-rust
  (list "newsboat"))

(define %not-for-work-no-rust
  (list))

(define %headless
  (list))
  ;(list "pinentry-tty"))

(define %guix-system-apps
  ;; These packages are provided by Guix System.
  (list "guile"
        "guile-colorized"
        "guile-readline"
        ;"mcron"
        ;"shepherd"
        ))

(define %cli-apps
  (list "aria2"
        "aspell"
        "aspell-dict-en"
        "aspell-dict-he"
        "bidiv"
        "bash-completion"
        "file"
        "git"
        "git:send-email"
        "glibc-locales"
        "global"
        "gnupg"
        "hunspell-dict-en"
        "links"
        "myrepos"
        "ncdu"
        "nmap"
        "nss-certs"
        "openssh"
        "parallel"
        "qrencode"
        "rsync"
        "screen"
        "stow"
        "tig"
        "torsocks"
        "translate-shell"
        "tree"
        "urlscan"
        "vifm"
        "vim"
        "vim-airline"
        "vim-dispatch"
        "vim-fugitive"
        "vim-gnupg"
        "vim-guix-vim"
        "editorconfig-vim"
        "wcalc"
        "wget"
        "wgetpaste"))


;; https://guix.gnu.org/manual/devel/en/html_node/Defining-Package-Variants.html

(define S specification->package)

;(define package-transformations
;  (options->transformation
;   (if (false-if-exception (S "ssl-ntv"))
;     `((with-graft . "openssl=ssl-ntv")
;       (with-branch . "vim-guix-vim=master"))
;     '((with-branch . "vim-guix-vim=master")))))

;; https://guix.gnu.org/manual/devel/en/html_node/Defining-Package-Variants.html#index-input-rewriting
;; Both of these are equivilent to '--with-input'
;; package-input-rewriting => takes an 'identity'
;; package-input-rewriting/spec => takes a name

;(define modified-packages
;  (package-input-rewriting/spec
;   ;; We leave the conditional here too to prevent searching for (dfsg main sdl).
;   `(("sdl2" . ,(if work-machine?
;                  (const (S "sdl2"))
;                  (const (@ (dfsg main sdl) sdl2-2.0.14)))))))

(packages->manifest
  (map (compose list specification->package+output)
       (append
         (if (or headless?
                 ;(target-aarch64?)
                 (not guix-system))
           %headless
           %GUI-only)
         (if work-machine?
           %work-applications
           (append
             %not-for-work
             ;(match (utsname:machine (uname))
             ;       ("x86_64" (append %not-for-work-ghc %not-for-work-rust))
             ;       ("i686" (append %not-for-work-ghc %not-for-work-no-rust))
             ;       (_ %not-for-work-no-rust))))
             (cond
               ((or (target-arm?) (target-powerpc?) (target-riscv64?))
                %not-for-work-no-rust)
               ((target-x86-64?)
                (append %not-for-work-ghc %not-for-work-rust))
               ((target-x86-32?)
                (append %not-for-work-ghc %not-for-work-no-rust))
               (else %not-for-work-no-rust))))
         (if guix-system
           '()
           %guix-system-apps)
         %cli-apps)))
