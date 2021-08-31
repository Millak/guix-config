(define-module (Guix_manifest))
(use-modules (guix profiles)
             (guix transformations)
             (guix packages)
             (gnu packages)
             (ice-9 match)
             (srfi srfi-1))

(define headless?
  (eq? #f (getenv "DISPLAY")))

(define UTenn_machines
  (list "lily"
        "penguin2"
        "tux01"
        "tux02"
        "tux03"
        "octopus01"
        "octopus02"
        "octopus03"
        "octopus04"
        "octopus05"
        "octopus06"
        "octopus07"
        "octopus08"
        "octopus09"
        "octopus10"
        "octopus11"
        ))

(define guix-system
  (file-exists? "/run/current-system/provenance"))

(define work-machine?
  (not (eq? #f (member (gethostname)
                       (cons "bayfront"
                             UTenn_machines)))))

(define %GUI-only
  (list "adwaita-icon-theme"
        "ephoto"
        "etui"
        "evisum"
        "font-culmus"
        "font-dejavu"
        ;"font-ghostscript"
        "font-gnu-freefont"
        "font-gnu-unifont"
        "font-opendyslexic"
        "font-terminus"
        "flatpak"
        "gs-fonts"
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
        "my-moreutils"
        "netsurf"
        "pavucontrol"
        "pinentry-efl"
        "qtwayland"
        "quassel"
        "terminology"
        "viewnior"
        "xclip"))

(define %work-applications
  (list "diffoscope"
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
        "youtube-dl"))

(define %not-for-work-ghc
  (list "git-annex"))

(define %not-for-work-rust
  (list "newsboat"))

(define %not-for-work-no-rust
  (list "newsboat@2.13"))

(define %headless
  (list "pinentry-tty"))

(define %guix-system-apps
  ;; These packages are provided by Guix System.
  (list "guile"
        "guile-colorized"
        "guile-readline"
        "mcron"
        "shepherd"))

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
        "glibc-utf8-locales"
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
        "vim"
        "vim-airline"
        "vim-dispatch"
        "vim-fugitive"
        "vim-guix-vim"
        "wcalc"
        "wget"
        "wgetpaste"))


;; https://guix.gnu.org/manual/devel/en/html_node/Defining-Package-Variants.html

(define package-transformations
  (options->transformation
   '(;; This graft sometimes causes trouble with git.
     ;(with-graft . "openssl=ssl-ntv")
     (with-branch . "vim-guix-vim=master"))))

;; https://guix.gnu.org/manual/devel/en/html_node/Defining-Package-Variants.html#index-input-rewriting
;; Both of these are equivilent to '--with-input'
;; package-input-rewriting => takes an 'identity'
;; package-input-rewriting/spec => takes a name

(define modified-packages
  (package-input-rewriting/spec
   `(("sdl2" . ,(const (@ (dfsg main sdl) sdl2-2.0.14))))))

(packages->manifest
  (map package-transformations
       (map modified-packages
            (map specification->package+output
                 (append
                   (if headless?
                     %headless
                     %GUI-only)
                   (if work-machine?
                     %work-applications
                     (append
                       %not-for-work
                       (match (utsname:machine (uname))
                              ("x86_64" (append %not-for-work-ghc %not-for-work-rust))
                              ("i686" (append %not-for-work-ghc %not-for-work-no-rust))
                              (_ %not-for-work-no-rust))))
                   (if (file-exists? "/run/current-system")
                     '()
                     %guix-system-apps)
                   %cli-apps)))))
