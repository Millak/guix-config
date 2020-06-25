(use-modules (guix profiles)
             (gnu packages)
             (srfi srfi-1))

(define headless?
  (eq? #f (getenv "DISPLAY")))

(define UTenn_machines
  (list "lily"
        "penguin2"
        "tux01"
        "tux02"))

(define work-machine?
  (not (eq? #f (member (gethostname)
                       (cons "bayfront"
                             UTenn_machines)))))

(define %GUI-only
  (list "ephoto"
        "etui"
        "evisum"
        "font-culmus"
        "font-dejavu"
        "font-gnu-freefont"
        "font-gnu-unifont"
        "font-opendyslexic"
        "font-terminus"
        "gs-fonts"
        "gst-plugins-good"
        "gst-plugins-ugly"
        "icecat"
        "intel-vaapi-driver"
        "kdeconnect"
        "keepassxc"
        "libreoffice"
        "mpv"
        "mpv-mpris"
        "my-moreutils"
        "my-pinentry-efl"
        "netsurf"
        "pavucontrol"
        "quassel"
        "terminology"
        "tilda"
        "viewnior"
        "xclip"))

(define %work-applications
  (list "diffoscope"
        "mercurial"))

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
        "newsboat"
        "parcimonie"
        "sshfs"
        "syncthing"
        "toot"
        "tuir"
        "vdirsyncer"
        "weechat"
        "youtube-dl"))

(define %intel-only-not-for-work
  (list "git-annex"))

(define %headless
  (list "pinentry-tty"))

(define %guix-system-apps
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
        "gnupg"
        "links"
        "mosh"
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
        "vim-asyncrun"
        "vim-fugitive"
        "vim-guix-vim"
        "wcalc"
        "wget"
        "wgetpaste"))

(packages->manifest
 (map (compose list specification->package+output)
      (append (if headless?
                %headless
                %GUI-only)
              (if work-machine?
                %work-applications
                (if (member (utsname:machine (uname))
                            '("x86_64" "i686"))
                  (append %intel-only-not-for-work %not-for-work)
                  %not-for-work))
              %guix-system-apps
              %cli-apps)))
