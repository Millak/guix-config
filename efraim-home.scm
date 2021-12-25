(define-module (efraim-home)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix transformations)
  #:use-module (guix gexp)
  #:use-module (ice-9 match))

;;;

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
        "octopus11"))

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
        "mupdf"
        "my-moreutils"
        "netsurf"
        "pavucontrol"
        "pinentry-efl"
        "qtwayland"
        "quassel"
        "qutebrowser"
        "terminology"
        "viewnior"
        "wl-clipboard-x11"
        "zathura"
        "zathura-pdf-poppler"))

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
        "yt-dlp"))

(define %not-for-work-ghc
  (list "git-annex"))

(define %not-for-work-rust
  (list "newsboat"))

(define %not-for-work-no-rust
  (list))

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
        ;"git:send-email"   ; listed below
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
        "vim"
        "vim-airline"
        "vim-dispatch"
        "vim-fugitive"
        "vim-gnupg"
        "vim-guix-vim"
        "wcalc"
        "wget"
        "wgetpaste"))


;; https://guix.gnu.org/manual/devel/en/html_node/Defining-Package-Variants.html

(define S specification->package)

(define package-transformations
  (options->transformation
   (if (false-if-exception (S "ssl-ntv"))
     `((with-graft . "openssl=ssl-ntv")
       (with-branch . "vim-guix-vim=master"))
     '((with-branch . "vim-guix-vim=master")))))

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

(define package-list
  (map specification->package+output
       (append
         (if (or headless?
                 (not guix-system))
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
         (if guix-system
           '()
           %guix-system-apps)
         %cli-apps)))

(define transformed-package-list
  (cons (list (package-transformations
                (S "git")) "send-email")
         (map package-transformations
                package-list)))

;;;

(define %mpv-conf
  (plain-file
    "mpv.conf"
    "no-audio-display\n"))

(define %inputrc
  (plain-file
    "inputrc"
    (string-append
      "set show-mode-in-prompt on\n"
      "set enable-bracketed-paste on\n"
      "set editing-mode vi\n"
      "Control-l: clear-screen\n"
      "set bell-style visible\n")))

(define %screenrc
  (plain-file
    "screenrc"
    (string-append
      "startup_message off\n"
      "term screen-256color\n"
      "defscrollback 50000\n"
      "altscreen on\n"
      "termcapinfo xterm* ti@:te@\n"
      "hardstatus alwayslastline '%{= G}[ %{G}%H %{g}][%= %{= w}%?%-Lw%?%{= R}%n*%f %t%?%{= R}(%u)%?%{= w}%+Lw%?%= %{= g}][ %{y}Load: %l %{g}][%{B}%Y-%m-%d %{W}%c:%s %{g}]'\n")))

(define %wcalcrc
  (plain-file
    "wcalcrc"
    (string-append
      "color=yes\n")))

(define %wgetpaste.conf
  (plain-file
    "wgetpaste.conf"
    (string-append
      "DEFAULT_NICK=efraim\n"
      "DEFAULT_EXPIRATION=1month\n")))

;; This clears the defaults, do not use
(define %lesskey
  (plain-file
    "lesskey"
    (string-append
      "#env\n"
      "LESS = --ignore-case --mouse --use-color --RAW-CONTROL-CHARS\n")))

(define %mailcap
  (mixed-text-file
    "mailcap"
    "text/html; " (S "links") "/bin/links -dump %s; nametemplate=%s.html; copiousoutput\n"))

(define %signature
  (plain-file
    "signature"
    (string-append
      ;"Efraim Flashner   <efraim@flashner.co.il>   רנשלפ םירפא\n"
      "Efraim Flashner   <efraim@flashner.co.il>   אפרים פלשנר\n"
      "GPG key = A28B F40C 3E55 1372 662D  14F7 41AA E7DC CA3D 8351\n"
      "Confidentiality cannot be guaranteed on emails sent or received unencrypted\n")))

(define %cvsrc
  (plain-file
    "cvsrc"
    (string-append
      "CVS configuration file from the pkgsrc guide\n"
      "cvs -q -z2\n"
      "checkout -P\n"
      "update -dP\n"
      "diff -upN\n"
      "rdiff -u\n"
      "release -d\n")))

(define %hgrc
  (mixed-text-file
    "hgrc"
    "[ui]\n"
    "username = Efraim Flashner <efraim@flashner.co.il\n"
    "[web]\n"
    ;"cacerts = " (ca-certificate-bundle (packages->manifest (list nss-certs))) " \n"))
    "cacerts = /etc/ssl/certs/ca-certificates.crt\n"))

(define %ytdl-config
  (plain-file
    "youtube-dl-config"
    (string-append
      "--prefer-free-formats\n"
      "--sub-lang 'en,he'\n"
      "--sub-format \"srt/best\"\n"
      "--convert-subtitles srt\n"
      "--restrict-filenames\n")))

(define %streamlink-config
  (mixed-text-file
    "streamlink-config"
    "default-stream 720p,1080p,best\n"
    "player=" (S "mpv") "/bin/mpv\n"))

(define %aria2-config
  (plain-file
    "aria2.conf"
    (string-append
      "check-integrity=true\n")))

(define %pbuilderrc
  (mixed-text-file
    "pbuilderrc"
    "MIRRORSITE=http://deb.debian.org/debian-ports\n"
    "DEBOOTSTRAPOPTS=( '--variant=buildd' '--keyring' '" (S "debian-ports-archive-keyring") "/share/keyrings/debian-ports-archive-keyring.gpg' )\n"
    "EXTRAPACKAGES=\"debian-ports-archive-keyring\"\n"
    ;"PBUILDERSATISFYDEPENDSCMD=" (S "pbuilder") "/lib/pbuilder/pbuilder-satisfydepends-apt\n"
    "PBUILDERSATISFYDEPENDSCMD=/usr/lib/pbuilder/pbuilder-satisfydepends-apt\n"
    ;"HOOKDIR=/home/efraim/.config/pbuilder/hooks\n"
    "APTCACHE=\"/var/cache/apt/archives\"\n"
    "AUTO_DEBSIGN=yes\n"
    "CCACHEDIR=/var/cache/pbuilder/ccache\n"
    "BINNMU_MAINTAINER=\"Efraim Flashner <efraim@flashner.co.il>\"\n"))

(define %gpg.conf
  (plain-file
    "gpg.conf"
    (string-append
      "default-key CA3D8351\n"
      "charset utf-8\n"
      "with-fingerprint\n"
      ;"keyserver hkp://keys.openpgp.org\n"
      ;"keyserver hkp://keyserver.ubuntu.com\n"
      "keyserver hkp://keys.gnupg.net\n"
      "keyserver-options auto-key-retrieve\n"
      "keyserver-options include-revoked\n"
      "keyserver-options no-honor-keyserver-url\n"
      "list-options show-uid-validity\n"
      "verify-options show-uid-validity\n"
      "keyid-format 0xlong\n"
      "auto-key-locate wkd cert pka ldap hkp://keys.gnupg.net\n"
      "personal-cipher-preferences AES256 AES192 AES CAST5\n"
      "personal-digest-preferences SHA512 SHA384 SHA256 SHA224\n"
      "cert-digest-algo SHA512\n"
      "default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed\n"
      "trust-model tofu+pgp\n")))

(define %gpg-agent.conf
  (mixed-text-file
    "gpg-agent.conf"
    #~(if #$headless?
        (string-append "pinentry-program " #$(file-append (S "pinentry-tty") "/bin/pinentry-tty") "\n")
        (string-append "pinentry-program " #$(file-append (S "pinentry-efl") "/bin/pinentry-efl") "\n"))
    ;"enable-ssh-support\n"
    "ignore-cache-for-signing\n"))

(define %git-config
  (mixed-text-file
    "git-config"
    "[user]\n"
    "    name = Efraim Flashner\n"
    "    email = efraim@flashner.co.il\n"
    "    signingkey = 0xca3d8351\n"
    "[core]\n"
    "    editor = " (S "vim") "/bin/vim\n"
    "[submodule]\n"
    "    fetchJobs = 5\n"
    "[format]\n"
    "    coverletter = auto\n"
    "    useAutoBase = true\n"
    "    signature-file = " %signature "\n"
    "    thread = shallow\n"
    "[diff]\n"
    "    algorithm = patience\n"
    "[sendemail]\n"
    "    smtpEncryption = ssl\n"
    #~(if #$work-machine?
        (string-append "    smtpServer = flashner.co.il\n"
                       "    smtpUser = efraim\n"
                       ;"    smtpsslcertpath = \"\"\n"
        )
        (string-append "    smtpServer = " #$(file-append (S "msmtp") "/bin/msmtpq") "\n"))
    "    smtpUser = efraim\n"
    "    smtpPort = 465\n"
    "    supresscc = self\n"
    "    transferEncoding = 8bit\n"
    "    annotate = yes\n"
    "[color]\n"
    "    ui = auto\n"
    "    branch = auto\n"
    "    diff = auto\n"
    "    status = auto\n"
    "[imap]\n"
    "    folder = Drafts\n"
    "    tunnel = \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il /usr/lib/dovecot/imap ./Maildir 2> /dev/null\"\n"
    "[transfer]\n"
    "    fsckObjects = true\n"
    #~(if #$work-machine?
        ""
        (string-append "[gpg]\n"
                       "    program = " #$(file-append (S "gnupg") "/bin/gpg") "\n"
                       "[commit]\n"
                       "    gpgSign = true\n"))
    "[web]\n"
    #~(if (or #$headless? #$work-machine?)
        (string-append "    browser = " #$(file-append (S "links") "/bin/links") "\n")
        (string-append "    browser = " #$(file-append (S "netsurf") "/bin/netsurf-gtk3") "\n"))
    "[pull]\n"
    "    rebase = true\n"
    "[fetch]\n"
    "    prune = true\n"))

(define %git-ignore
  (plain-file
    "ignore"
    (string-append
      "*~\n"
      "*sw?\n"
      ".vimrc\n"
      "gtags.files\n"
      "GPATH\n"
      "GRTAGS\n"
      "GTAGS\n")))

;; This part does not work yet.
;(define %bg.edc
;  (plain-file
;    "bg.edc"
;      "images {
;      set { name: \"guix-checkered-16-9\";
;      image {
;      image: \"guix-checkered-16-9.svg\" LOSSY 100;
;      size: 1920 1080 1000000000 1000000000;}}}
;      collections {
;      group { name: \"e/desktop/background\";
;      data.item: \"noanimation\" \"1\";
;      data { item: \"style\" \"4\"; }
;      parts {
;      part { name: \"bg\"; mouse_events: 0;
;      description { state: \"default\" 0;
;      image {
;      normal: \"guix-checkered-16-9\";
;      scale_hint: STATIC;}
;      aspect: (1920/1080) (1920/1080); aspect_preference: NONE;}}}}}"))
;
;(define %guix-background
;  (computed-file "guix-checkered-16-9.edj"
;    #~(begin
;        (system* #+(file-append (S "efl") "/bin/edje_cc") "-id" #$(file-append (@ (gnu artwork) %artwork-repository) "/backgrounds") #$%bg.edc "-o" #$output))))

;;;

(define %logdir
  (or (getenv "XDG_LOG_HOME")
      (format #f "~a/.local/var/log"
              (getenv "HOME"))))

(define %mbsyncrc
  (mixed-text-file
    "mbsyncrc"
    "# Global values\n"
    "Expunge Both\n"
    "Create Near\n"
    "MaildirStore local\n"
    "Path ~/Maildir/\n"
    "Inbox ~/Maildir/INBOX\n"
    "#MapInbox INBOX\n"
    "#Trash Trash\n"
    "Flatten .\n"
    "#SubFolders Verbatim\n"
    "\n"
    "IMAPStore flashner\n"
    "Host flashner.co.il\n"
    "#PassCmd \"" (S "gnupg") "/bin/gpg --quiet --for-your-eyes-only --decrypt $HOME/.msmtp.password.gpg\"\n"
    "#SSLType IMAPS\n"
    "#CertificateFile /etc/ssl/certs/ca-certificates.crt\n"
    "Timeout 120 # 25 * 8 / 2\n"
    "Tunnel \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il 'MAIL=maildir:~/Maildir exec /usr/lib/dovecot/imap'\"\n"
    "\n"
    "Channel flashner\n"
    "Far :flashner:\n"
    "Near :local:\n"
    "Patterns * !work\n"))

(define work-home-environment
  (home-environment
    (packages transformed-package-list)
    ;; TODO: adjust services based on machine type.
    (services
      (list
        (service home-bash-service-type
                 (home-bash-configuration
                   (guix-defaults? #t)
                   (environment-variables
                     `(("QT_QPA_PLATFORM" . "wayland")
                       ("ECORE_EVAS_ENGINE" . "wayland_egl")
                       ("ELM_ENGINE" . "wayland_egl")
                       ;; TODO: enable after sdl >= 2.0.14
                       ;; Apparently only a problem on enlightenment/wayland.
                       ("SDL_VIDEODRIVER" . "wayland")
                       ;; ("MOZ_ENABLE_WAYLAND" . "1")
                       ("EDITOR" . ,(file-append (S "vim") "/bin/vim"))
                       ("GPG_TTY" . "$(tty)")
                       ("HISTSIZE" . "3000")
                       ("HISTFILESIZE" . "10000")
                       ("HISTCONTROL" . "ignorespace")
                       ("HISTIGNORE" . "'pwd:exit:fg:bg:top:clear:history:ls:uptime:df'")
                       ("PROMPT_COMMAND" . "\"history -a; $PROMPT_COMMAND\"")))
                   (bash-profile
                     (list
                       (mixed-text-file "bash-profile" "\
unset SSH_AGENT_PID
if [ \"${gnupg_SSH_AUTH_SOCK_by:-0}\" -ne $$ ]; then
    export SSH_AUTH_SOCK=\"$(" (S "gnupg") "/bin/gpgconf --list-dirs agent-ssh-socket)\"
fi
#if [ -d ${HOME}/.cache/efreet ]; then
#    rm -rf -- ${HOME}/.cache/efreet
#fi
if [ -d ${HOME}/.cache/tilda/locks ]; then
    rm -rf -- ${HOME}/.cache/tilda/locks
fi
if [ -d ${HOME}/.local/share/flatpak/exports/share ]; then
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:${HOME}/.local/share/flatpak/exports/share
fi
# This seems to be covered in guix-home-service.
#if [ $(which fc-cache 2>/dev/null) ]; then
#    fc-cache -frv &>/dev/null;
#fi")))
                   (bashrc
                     (list
                       (mixed-text-file "bashrc" "\
alias cp='cp --reflink=auto'
alias exitexit='exit'
alias clear=\"printf '\\E[H\\E[J\\E[0m'\"

#alias guix-u='~/workspace/guix/pre-inst-env guix package --fallback -L ~/workspace/my-guix/ -u . '
#alias guix-m='~/workspace/guix/pre-inst-env guix package --fallback -L ~/workspace/my-guix/ -m ~/workspace/guix-config/Guix_manifest.scm'
alias guix-home-build='~/workspace/guix/pre-inst-env guix home build --no-grafts --fallback -L ~/workspace/my-guix/ ~/workspace/guix-config/efraim-home.scm'
alias guix-home-reconfigure='~/workspace/guix/pre-inst-env guix home reconfigure --fallback -L ~/workspace/my-guix/ ~/workspace/guix-config/efraim-home.scm'")))))

        (simple-service 'aria2-config
                        home-files-service-type
                        (list `("config/aria2/aria2.conf"
                                ,%aria2-config)))

        (simple-service 'cvsrc-config
                        home-files-service-type
                        (list `("cvsrc"
                                ,%cvsrc)))

        (simple-service 'git-config
                        home-files-service-type
                        (list `("config/git/config"
                                ,%git-config)))

        (simple-service 'git-ignore
                        home-files-service-type
                        (list `("config/git/ignore"
                                ,%git-ignore)))

        (simple-service 'gnupg-conf
                      home-files-service-type
                      (list `("gnupg/gpg.conf"
                              ,%gpg.conf)))

        (simple-service 'gnupg-agent-conf
                        home-files-service-type
                        (list `("gnupg/gpg-agent.conf"
                                ,%gpg-agent.conf)))

        (simple-service 'hgrc-config
                        home-files-service-type
                        (list `("hgrc"
                                ,%hgrc)))

        (simple-service 'inputrc-config
                        home-files-service-type
                        (list `("inputrc"
                                ,%inputrc)))

        ;; This clears the defaults, do not use.
        ;(simple-service 'less-config
        ;                home-files-service-type
        ;                (list `("config/lesskey"
        ;                        ,%lesskey)))

        ;; Not sure about using this one.
        ;(simple-service 'mailcap-config
        ;                home-files-service-type
        ;                (list `("mailcap"
        ;                        ,%mailcap)))

        (simple-service 'pbuilderrc
                        home-files-service-type
                        (list `("pbuilderrc"
                                ,%pbuilderrc)))

        (simple-service 'screenrc
                        home-files-service-type
                        (list `("screenrc"
                                ,%screenrc)))

        (simple-service 'signature
                        home-files-service-type
                        (list `("signature"
                                ,%signature)))

        (simple-service 'wcalcrc
                        home-files-service-type
                        (list `("wcalcrc"
                                ,%wcalcrc)))

        (simple-service 'wgetpaste-conf
                        home-files-service-type
                        (list `("wgetpaste.conf"
                                ,%wgetpaste.conf)))))))

(define my-home-environment
  (home-environment
    (inherit work-home-environment)
    (services
      (append
        (home-environment-user-services work-home-environment)
        (list
          (service home-shepherd-service-type
            (home-shepherd-configuration
              (services
                (list
                  (shepherd-service
                    (documentation "Run `syncthing' without calling the browser")
                    (provision '(syncthing))
                    (start #~(make-forkexec-constructor
                               (list #$(file-append (S "syncthing") "/bin/syncthing")
                                     "-no-browser")
                               #:log-file (string-append %logdir "/syncthing.log")))
                    (stop #~(make-kill-destructor))
                    (respawn? #t))

                  (shepherd-service
                    (documentation "Provide access to Dropbox™")
                    (provision '(dropbox dbxfs))
                    (start #~(make-forkexec-constructor
                               (list #$(file-append (S "dbxfs") "/bin/dbxfs")
                                     "--foreground"
                                     "--verbose"
                                     "/home/efraim/Dropbox")
                               #:log-file (string-append %logdir "/dbxfs.log")))
                    ;; Perhaps I want to use something like this?
                    ;(stop (or #~(make-system-destructor
                    ;              (string-append
                    ;                #$(file-append (S "fuse") "/bin/fusermount")
                    ;                " -u /home/efraim/Dropbox"))
                    ;          #~(make-system-destructor
                    ;              "fusermount -u /home/efraim/Dropbox")))
                    (stop #~(make-system-destructor
                              "fusermount -u /home/efraim/Dropbox"))
                    (respawn? #f))

                  ;; This can probably be moved to an mcron service.
                  (shepherd-service
                    (documentation "Run vdirsyncer hourly")
                    (provision '(vdirsyncer))
                    (start
                      #~(lambda args
                          (match (primitive-fork)
                                 (0 (begin
                                      (while #t
                                             (system* #$(file-append (S "vdirsyncer")
                                                                     "/bin/vdirsyncer")
                                                      "sync")
                                             ;; Random time between 30 and 45 minutes.
                                             (sleep (+ (* 30 60)
                                                       (random
                                                         (* 15 60)))))))
                                 (pid pid))))
                    (stop #~(make-kill-destructor))
                    (respawn? #t))

                  (shepherd-service
                    (documentation "Connect to UTHSC VPN")
                    (provision '(uthsc-vpn openconnect))
                    (start #~(make-forkexec-constructor
                              (list #$(file-append (S "openconnect-sso")
                                                   "/bin/openconnect-sso")
                                    "--server"
                                    "uthscvpn1.uthsc.edu")
                              #:log-file (string-append %logdir "/uthsc-vpn.log")))
                    (auto-start? #f)
                    (respawn? #f))

                  (shepherd-service
                    (documentation "Sync mail to the local system")
                    (provision '(mbsync))
                    (start
                      #~(lambda args
                          (match (primitive-fork)
                                 (0 (begin
                                      (while #t
                                             (system* #$(file-append (S "isync")
                                                                     "/bin/mbsync")
                                                      "--config" #$%mbsyncrc
                                                      "--all")
                                             ;; Random time between 45 and 60 seconds
                                             (sleep (+ 45 (random 15))))))
                                 (pid pid))))
                    (stop #~(make-kill-destructor))
                    (respawn? #t))

                  ;; https://github.com/keybase/client/blob/master/packaging/linux/systemd/keybase.service
                  (shepherd-service
                    (documentation "Provide access to Keybase™")
                    (provision '(keybase))
                    (start #~(make-forkexec-constructor
                               (list #$(file-append (S "keybase") "/bin/keybase")
                                     "service")
                               #:log-file (string-append %logdir "/keybase.log")
                               #:directory #~(string-append
                                               "/run/user/"
                                               (number->string
                                                 (passwd:uid (getpw "efraim")))
                                               "/keybase")))
                    (stop #~(make-system-destructor
                              (string-append #$(file-append (S "keybase")
                                                            "/bin/keybase")
                                             " ctl stop")))
                    (respawn? #t))

                  ;; https://github.com/keybase/client/blob/master/packaging/linux/systemd/kbfs.service
                  (shepherd-service
                    (documentation "Provide access to Keybase™ fuse store")
                    (requirement '(keybase))
                    (provision '(kbfs))
                    (start #~(make-forkexec-constructor
                               (list #$(file-append (S "keybase") "/bin/kbfsfuse")
                                     ;"-debug"
                                     "-log-to-file")
                               #:log-file (string-append %logdir "/kbfs.log")))
                    (stop #~(make-kill-destructor))
                    (respawn? #t))

                  ;; kdeconnect-indicator must not be running when it it started
                  (shepherd-service
                    (documentation "Run the KDEconnect daemon")
                    (provision '(kdeconnect))
                    (start #~(make-forkexec-constructor
                               (list #$(file-append (S "kdeconnect") "/libexec/kdeconnectd")
                                     "-platform" "offscreen")
                               #:log-file (string-append %logdir "/kdeconnect.log")))
                    (stop #~(make-kill-destructor)))

                  (shepherd-service
                    (documentation "Incrementally refresh gnupg keyring")
                    (provision '(parcimonie))
                    (start #~(make-forkexec-constructor
                               (list #$(file-append (S "parcimonie") "/bin/parcimonie")
                                     "--gnupg_extra_args"
                                     "--keyring=/home/efraim/.config/guix/upstream/trustedkeys.kbx"
                                     "--gnupg_extra_args"
                                     "--keyring=/home/efraim/.config/guix/gpg/trustedkeys.kbx")
                               #:log-file (string-append %logdir "/parcimonie.log")))
                    (stop #~(make-kill-destructor))
                    (respawn? #t))))))

          ;(simple-service 'enlightenment-background
          ;                home-files-service-type
          ;                (list `("e/e/backgrounds/guix-checkered-16-9.edj"
          ;                        %guix-background)))

          ;; TODO: Make this work
          ;(simple-service 'lagrange-fonts
          ;                home-files-service-type
          ;                (list `("config/lagrange/fonts")
          ;                      ,"guix-profile/share/fonts/truetype"))

          (simple-service 'mpv-mpris
                          home-files-service-type
                          (list `("config/mpv/scripts/mpris.so"
                                  ,(file-append (S "mpv-mpris") "/lib/mpris.so"))))

          (simple-service 'mpv-sponsorblock
                          home-files-service-type
                          (list `("config/mpv/scripts/sponsorblock_minimal.lua"
                                  ,(file-append
                                     (false-if-exception
                                       (S "mpv-sponsorblock-minimal"))
                                     "/lib/sponsorblock_minimal.lua"))))

          (simple-service 'mpv-twitch-chat
                          home-files-service-type
                          (list `("config/mpv/scripts/twitch-chat/main.lua"
                                  ,(file-append
                                     (false-if-exception
                                       (S "mpv-twitch-chat"))
                                     "/lib/main.lua"))))

          (simple-service 'mpv-conf
                          home-files-service-type
                          (list `("config/mpv/conf"
                                  ,%mpv-conf)))

          (simple-service 'streamlink-conf
                          home-files-service-type
                          (list `("config/streamlink/config"
                                  ,%streamlink-config)))

          (simple-service 'youtubedl-conf
                          home-files-service-type
                          (list `("config/youtube-dl/config"
                                  ,%ytdl-config)))
          (simple-service 'yt-dlp-conf
                          home-files-service-type
                          (list `("config/yt-dlp/config"
                                  ,%ytdl-config))))))))

(if work-machine?
  work-home-environment
  my-home-environment)
