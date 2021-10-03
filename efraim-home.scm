(define-module (efraim-home)
  #:use-module (gnu home)
  #:use-module (gnu home-services)
  #:use-module (gnu home-services shells)
  #:use-module (gnu services)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix transformations)
  #:use-module (guix gexp)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages video)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages web)
  #:use-module (gnu packages web-browsers)
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
        ;"git:send-email"   ; listed below
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
   (if (false-if-exception (specification->package "ssl-ntv"))
     `((with-graft . "openssl=ssl-ntv")
       (with-branch . "vim-guix-vim=master"))
     '((with-branch . "vim-guix-vim=master")))))

;; https://guix.gnu.org/manual/devel/en/html_node/Defining-Package-Variants.html#index-input-rewriting
;; Both of these are equivilent to '--with-input'
;; package-input-rewriting => takes an 'identity'
;; package-input-rewriting/spec => takes a name

(define modified-packages
  (package-input-rewriting/spec
   `(("sdl2" . ,(if work-machine?
                  (const (specification->package "sdl2"))
                  (const (@ (dfsg main sdl) sdl2-2.0.14)))))))

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
                (specification->package "git")) "send-email")
         (map package-transformations
              (map modified-packages
                   package-list))))

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
    "text/html; " links "/bin/links -dump %s; nametemplate=%s.html; copiousoutput\n"))

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
    "player=" mpv "/bin/mpv\n"))

(define %aria2-config
  (plain-file
    "aria2.conf"
    (string-append
      "check-integrity=true\n")))

(define %pbuilderrc
  (mixed-text-file
    "pbuilderrc"
    (string-append
      "MIRRORSITE=http://deb.debian.org/debian-ports\n"
      ;"DEBOOTSTRAPOPTS=( '--variant=buildd' '--keyring' '" (specification->package "debian-ports-archive-keyring") "/share/keyrings/debian-ports-archive-keyring.gpg' )\n"
      "DEBOOTSTRAPOPTS=( '--variant=buildd' '--keyring' '/usr/share/keyrings/debian-ports-archive-keyring.gpg' )\n"
      "EXTRAPACKAGES=\"debian-ports-archive-keyring\"\n"
      ;"PBUILDERSATISFYDEPENDSCMD=" (specification->package "pbuilder") "/lib/pbuilder/pbuilder-satisfydepends-apt\n"
      "PBUILDERSATISFYDEPENDSCMD=/usr/lib/pbuilder/pbuilder-satisfydepends-apt\n"
      ;"HOOKDIR=/home/efraim/.config/pbuilder/hooks\n"
      "APTCACHE=\"/var/cache/apt/archives\"\n"
      "AUTO_DEBSIGN=yes\n"
      "CCACHEDIR=/var/cache/pbuilder/ccache\n"
      "BINNMU_MAINTAINER=\"Efraim Flashner <efraim@flashner.co.il>\"\n")))

(define %gpg.conf
  (plain-file
    "gpg.conf"
    (string-append
      "default-key CA3D8351\n"
      "charset utf-8\n"
      "with-fingerprint\n"
      "keyserver hkp://keys.openpgp.org\n"
      "keyserver hkp://keyserver.ubuntu.com\n"
      "keyserver-options auto-key-retrieve\n"
      "keyserver-options include-revoked\n"
      "keyserver-options no-honor-keyserver-url\n"
      "list-options show-uid-validity\n"
      "verify-options show-uid-validity\n"
      "keyid-format 0xlong\n"
      "auto-key-locate wkd cert pka ldap hkp://keys.openpgp.org hkp://keyserver.ubuntu.com\n"
      "personal-cipher-preferences AES256 AES192 AES CAST5\n"
      "personal-digest-preferences SHA512 SHA384 SHA256 SHA224\n"
      "cert-digest-algo SHA512\n"
      "default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed\n"
      "trust-model tofu+pgp\n")))

(define %gpg-agent.conf
  (mixed-text-file
    "gpg-agent.conf"
    #~(if #$headless?
        (string-append "pinentry-program " #$(file-append pinentry-tty "/bin/pinentry-tty") "\n")
        (string-append "pinentry-program " #$(file-append pinentry-efl "/bin/pinentry-efl") "\n"))))

;; TODO: Adjust based on work machine or headless.
(define %git-config
  (mixed-text-file
    "git-config"
    "[user]\n"
    "    name = Efraim Flashner\n"
    "    email = efraim@flashner.co.il\n"
    "    signingkey = 0xca3d8351\n"
    "[core]\n"
    "    editor = " vim "/bin/vim\n"
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
        "    smtpServer = flashner.co.il\n"
        ;"    smtp-ssl-cert-path = \"\"\n"
        (string-append "    smtpServer = " #$(file-append msmtp "/bin/msmtpq") "\n"))
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
    "    tunnel = \"" openssh "/bin/ssh -o Compression=yes -q flashner.co.il /usr/lib/dovecot/imap ./Maildir 2> /dev/null\"\n"
    "[transfer]\n"
    "    fsckObjects = true\n"
    #~(if #$work-machine?
        ""
        (string-append "[gpg]\n"
                       "    program = " #$(file-append gnupg "/bin/gpg") "\n"
                       "[commit]\n"
                       "    gpgSign = true\n"))
    "[web]\n"
    #~(if (or #$headless? #$work-machine?)
        (string-append "    browser = " #$(file-append links "/bin/links") "\n")
        (string-append "    browser = " #$(file-append netsurf "/bin/netsurf-gtk3") "\n"))
    "[pull]\n"
    "    rebase = true\n"))

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

;;;

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
                       ;TODO: enable after sdl >= 2.0.14
                       ("SDL_VIDEODRIVER" . "wayland")
                       ;("MOZ_ENABLE_WAYLAND" . "1")
                       ("EDITOR" . ,(file-append vim "/bin/vim"))
                       ("GPG_TTY" . "$(tty)")
                       ("HISTSIZE" . "3000")
                       ("HISTFILESIZE" . "10000")
                       ("HISTCONTROL" . "ignorespace")
                       ("HISTIGNORE" . "'pwd:exit:fg:bg:top:clear:history:ls:uptime:df'")
                       ("PROMPT_COMMAND" . "\"history -a; $PROMPT_COMMAND\"")))
                   (bash-profile
                     '("\
unset SSH_AGENT_PID
if [ \"${gnupg_SSH_AUTH_SOCK_by:-0}\" -ne $$ ]; then
    export SSH_AUTH_SOCK=\"$(gpgconf --list-dirs agent-ssh-socket)\"
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
#fi"))
                   (bashrc
                     '("\
allias cp='cp --reflink=auto'
alias clear=\"printf '\\E[H\\E[J\\E[0m'\"

alias guix-u='~/workspace/guix/pre-inst-env guix package --fallback -L ~/workspace/my-guix/ -u . '
alias guix-m='~/workspace/guix/pre-inst-env guix package --fallback -L ~/workspace/my-guix/ -m ~/workspace/guix-config/Guix_manifest.scm'
alias guix-home-build='~/workspace/guix/pre-inst-env guix home build --fallback -L ~/workspace/my-guix/ -m ~/workspace/guix-config/Guix_manifest.scm'"))))

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
          (simple-service 'mpv-mpris
                          home-files-service-type
                          (list `("config/mpv/scripts/mpris.so"
                                  ,(file-append mpv-mpris "/lib/mpris.so"))))

          (simple-service 'mpv-sponsorblock
                          home-files-service-type
                          (list `("config/mpv/scripts/sponsorblock_minimal.lua"
                                  ,(file-append
                                     (specification->package "mpv-sponsorblock-minimal")
                                     "/lib/sponsorblock_minimal.lua"))))

          (simple-service 'mpv-twitch-chat
                          home-files-service-type
                          (list `("config/mpv/scripts/twitch-chat/main.lua"
                                  ,(file-append
                                     (specification->package "mpv-twitch-chat")
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
                                  ,%ytdl-config))))))))

(if work-machine?
  work-home-environment
  my-home-environment)
