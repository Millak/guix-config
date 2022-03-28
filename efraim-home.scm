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

(define %logdir
  (or (getenv "XDG_LOG_HOME")
      (format #f "~a/.local/var/log"
              (getenv "HOME"))))

(define headless?
  (eq? #f (getenv "DISPLAY")))

(define UTenn_machines
  (list "lily"
        "penguin2"
        "tux01"
        "tux02"
        "tux03"
        "octopus01"))

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
        "quasselclient"
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
        "git-annex"
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
        "vdirsyncer"
        "weechat"
        "yt-dlp"))

(define %headless
  (list "pinentry-tty"))

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
        (if (package-transitive-supported-systems
              (specification->package "ncdu2"))
          "ncdu2"
          "ncdu")
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


(define S specification->package)

(define package-list
  (map (compose list specification->package+output)
       (filter (lambda (pkg)
                 (member (or (%current-system)
                             (%current-target-system))
                         (package-transitive-supported-systems
                           (specification->package+output pkg))))
              (append
                (if (or headless?
                        (not guix-system))
                  %headless
                  %GUI-only)
                (if work-machine?
                  %work-applications
                  %not-for-work)
                (if guix-system
                  '()
                  %guix-system-apps)
                %cli-apps))))

;;;

(define %mpv-conf
  (plain-file
    "mpv.conf"
    (string-append
      "no-audio-display\n"
      ;; Upscaling from 720 causes fewer dropped frames.
      "ytdl-format='bv*[height<=720]+ba/b[height<=720]/bv*[height<=1080]+ba/b[height<1080]/bv+ba/b'\n")))

(define %inputrc
  (plain-file
    "dot-inputrc"
    (string-append
      "set show-mode-in-prompt on\n"
      "set enable-bracketed-paste on\n"
      "set editing-mode vi\n"
      "Control-l: clear-screen\n"
      "set bell-style visible\n")))

(define %screenrc
  (plain-file
    "dot-screenrc"
    (string-append
      "startup_message off\n"
      "term screen-256color\n"
      "defscrollback 50000\n"
      "altscreen on\n"
      "termcapinfo xterm* ti@:te@\n"
      "hardstatus alwayslastline '%{= G}[ %{G}%H %{g}][%= %{= w}%?%-Lw%?%{= R}%n*%f %t%?%{= R}(%u)%?%{= w}%+Lw%?%= %{= g}][ %{y}Load: %l %{g}][%{B}%Y-%m-%d %{W}%c:%s %{g}]'\n")))

(define %wcalcrc
  (plain-file
    "dot-wcalcrc"
    (string-append
      "color=yes\n")))

(define %wgetpaste.conf
  (plain-file
    "dot-wgetpaste-conf"
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
    "dot-mailcap"
    "text/html; " (S "links") "/bin/links -dump %s; nametemplate=%s.html; copiousoutput\n"))

(define %signature
  (plain-file
    "dot-signature"
    (string-append
      ;; It shouldn't be this hard to always display correctly.
      ;"Efraim Flashner   <efraim@flashner.co.il>   רנשלפ םירפא\n"
      "Efraim Flashner   <efraim@flashner.co.il>   אפרים פלשנר\n"
      "GPG key = A28B F40C 3E55 1372 662D  14F7 41AA E7DC CA3D 8351\n"
      "Confidentiality cannot be guaranteed on emails sent or received unencrypted\n")))

(define %cvsrc
  (plain-file
    "dot-cvsrc"
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
    "dot-pbuilderrc"
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
      "keyserver hkp://keyserver.ubuntu.com\n"
      ;"keyserver hkp://keys.gnupg.net\n"
      "keyserver-options auto-key-retrieve\n"
      "keyserver-options include-revoked\n"
      "keyserver-options no-honor-keyserver-url\n"
      "list-options show-uid-validity\n"
      "verify-options show-uid-validity\n"
      ;"photo-viewer \"catimg $i\"\n"
      "keyid-format 0xlong\n"
      "use-agent\n"
      "auto-key-locate wkd cert pka ldap hkp://keys.gnupg.net hkp://keys.openpgp.org hkp://keyserver.ubuntu.com\n"
      "personal-cipher-preferences AES256 AES192 AES CAST5\n"
      "personal-digest-preferences SHA512 SHA384 SHA256 SHA224\n"
      "cert-digest-algo SHA512\n"
      "default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed\n"
      ;"default-cache-ttl 900\n"
      "trust-model tofu+pgp\n")))

(define %gpg-agent.conf
  (mixed-text-file
    "gpg-agent.conf"
    #~(if #$headless?
        (string-append "pinentry-program " #$(file-append (S "pinentry-tty") "/bin/pinentry-tty") "\n")
        (string-append "pinentry-program " #$(file-append (S "pinentry-efl") "/bin/pinentry-efl") "\n"))
    ;"enable-ssh-support\n"
    ;; This makes me sign each commit individually.
    ;"ignore-cache-for-signing\n"
    ))

(define %git-config
  (mixed-text-file
    "git-config"
    "[user]\n"
    "    name = Efraim Flashner\n"
    "    email = efraim@flashner.co.il\n"
    "    signingkey = 0xca3d8351\n"
    #~(if #$work-machine?
        ""
        (string-append "[commit]\n"
                       "    gpgSign = true\n"))
    "[color]\n"
    "    ui = auto\n"
    "    branch = auto\n"
    "    diff = auto\n"
    "    status = auto\n"
    "[core]\n"
    "    editor = " (S "vim") "/bin/vim\n"
    "[diff]\n"
    "    algorithm = patience\n"
    "[fetch]\n"
    "    prune = true\n"
    "[format]\n"
    "    coverletter = auto\n"
    "    useAutoBase = true\n"
    "    signature-file = " %signature "\n"
    "    thread = shallow\n"
    #~(if #$work-machine?
        ""
        (string-append "[gpg]\n"
                       "    program = " #$(file-append (S "gnupg") "/bin/gpg") "\n"))
    "[imap]\n"
    "    folder = Drafts\n"
    "    tunnel = \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il /usr/lib/dovecot/imap ./Maildir 2> /dev/null\"\n"
    "[pull]\n"
    "    rebase = true\n"
    "[sendemail]\n"
    "    smtpEncryption = ssl\n"
    #~(if #$work-machine?
        (string-append "    smtpServer = flashner.co.il\n"
                       ;"    smtpsslcertpath = \"\"\n"
        )
        (string-append "    smtpServer = " #$(file-append (S "msmtp") "/bin/msmtpq") "\n"))
    "    smtpUser = efraim\n"
    "    smtpPort = 465\n"
    "    supresscc = self\n"
    "    transferEncoding = 8bit\n"
    "    annotate = yes\n"
    "[submodule]\n"
    "    fetchJobs = 5\n"
    "[transfer]\n"
    "    fsckObjects = true\n"
    "[web]\n"
    #~(if (or #$headless? #$work-machine?)
        (string-append "    browser = " #$(file-append (S "links") "/bin/links") "\n")
        (string-append "    browser = " #$(file-append (S "netsurf") "/bin/netsurf-gtk3") "\n"))))

(define %git-ignore
  (plain-file
    "git-ignore"
    (string-append
      "*~\n"
      ".exrc\n"
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

(define %gdbinit
  (plain-file "dot-gdbinit" "\
# Tell GDB where to look for separate debugging files.
guile
(use-modules (gdb))
(execute (string-append \"set debug-file-directory \"
                        (or (getenv \"GDB_DEBUG_FILE_DIRECTORY\")
                            \"~/.guix-profile/lib/debug\")))
end

# Authorize extensions found in the store, such as the
# pretty-printers of libstdc++.
set auto-load safe-path /gnu/store/*/lib\n"))

(define %guile
  (plain-file "dot-guile"
              "(cond ((false-if-exception (resolve-interface '(ice-9 readline)))
       =>
       (lambda (module)
         ;; Enable completion and input history at the REPL.
         ((module-ref module 'activate-readline))))
      (else
       (display \"Consider installing the 'guile-readline' package for
convenient interactive line editing and input history.\\n\\n\")))

      (unless (getenv \"INSIDE_EMACS\")
        (cond ((false-if-exception (resolve-interface '(ice-9 colorized)))
               =>
               (lambda (module)
                 ;; Enable completion and input history at the REPL.
                 ((module-ref module 'activate-colorized))))
              (else
               (display \"Consider installing the 'guile-colorized' package
for a colorful Guile experience.\\n\\n\"))))\n"))

(define %nanorc
  (plain-file "nanorc" "\
# Include all the syntax highlighting modules.
include /run/current-system/profile/share/nano/*.nanorc\n"))

(define %xdefaults
  (plain-file "dot-Xdefaults" "\
XTerm*utf8: always
XTerm*metaSendsEscape: true\n"))

;;;

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

;;;

(define %syncthing-user-service
  (shepherd-service
    (documentation "Run `syncthing' without calling the browser")
    (provision '(syncthing))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "syncthing") "/bin/syncthing")
                     "-no-browser")
               #:log-file (string-append #$%logdir "/syncthing.log")))
    (stop #~(make-kill-destructor))
    (respawn? #t)))

(define %dropbox-user-service
  (shepherd-service
    (documentation "Provide access to Dropbox™")
    (provision '(dropbox dbxfs))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "dbxfs") "/bin/dbxfs")
                     "--foreground"
                     "--verbose"
                     "/home/efraim/Dropbox")
               #:log-file (string-append #$%logdir "/dbxfs.log")))
    ;; Perhaps I want to use something like this?
    ;(stop (or #~(make-system-destructor
    ;              (string-append
    ;                #$(file-append (S "fuse") "/bin/fusermount")
    ;                " -u " (getenv "HOME") "/Dropbox"))
    ;          #~(make-system-destructor
    ;              "fusermount -u /home/efraim/Dropbox")))
    (stop #~(make-system-destructor
              "fusermount -u /home/efraim/Dropbox"))
    ;; Needs gpg key to unlock
    (auto-start? #f)
    (respawn? #f)))

;; This can probably be moved to an mcron service.
(define %vdirsyncer-user-service
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
    (respawn? #t)))

(define %uthsc-vpn-user-service
  (shepherd-service
    (documentation "Connect to UTHSC VPN")
    (provision '(uthsc-vpn openconnect))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "openconnect-sso")
                                    "/bin/openconnect-sso")
                     "--server"
                     "uthscvpn1.uthsc.edu")
               #:log-file (string-append #$%logdir "/uthsc-vpn.log")))
    (auto-start? #f)
    (respawn? #f)))

(define %mbsync-user-service
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
    (respawn? #t)))

;; https://github.com/keybase/client/blob/master/packaging/linux/systemd/keybase.service
(define %keybase-user-service
  (shepherd-service
    (documentation "Provide access to Keybase™")
    (provision '(keybase))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "keybase") "/bin/keybase")
                     "service")
               #:log-file (string-append #$%logdir "/keybase.log")
               #:directory (string-append #$(getenv "XDG_RUNTIME_DIR") "/keybase")))
    (stop #~(make-system-destructor
              (string-append #$(file-append (S "keybase")
                                            "/bin/keybase")
                             " ctl stop")))
    ;; Starts too fast at login
    (auto-start? #f)
    (respawn? #t)))

;; https://github.com/keybase/client/blob/master/packaging/linux/systemd/kbfs.service
(define %keybase-fuse-user-service
  (shepherd-service
    (documentation "Provide access to Keybase™ fuse store")
    (requirement '(keybase))
    (provision '(kbfs))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "keybase") "/bin/kbfsfuse")
                     ;"-debug"
                     "-log-to-file")
               #:log-file (string-append #$%logdir "/kbfs.log")))
    (stop #~(make-kill-destructor))
    ;; Depends on keybase
    (auto-start? #f)
    (respawn? #t)))

;; kdeconnect-indicator must not be running when it it started
(define %kdeconnect-user-service
  (shepherd-service
    (documentation "Run the KDEconnect daemon")
    (provision '(kdeconnect))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "kdeconnect") "/libexec/kdeconnectd")
                     "-platform" "offscreen")
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/kdeconnect.log")))
    (stop #~(make-kill-destructor))))

(define %parcimonie-user-service
  (shepherd-service
    (documentation "Incrementally refresh gnupg keyring")
    (provision '(parcimonie))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "parcimonie") "/bin/parcimonie")
                     ;; Can I use compose and find or a list to make this work?
                     "--gnupg_extra_args"
                     "--keyring=/home/efraim/.config/guix/upstream/trustedkeys.kbx"
                     "--gnupg_extra_args"
                     "--keyring=/home/efraim/.config/guix/gpg/trustedkeys.kbx")
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/parcimonie.log")))
    (stop #~(make-kill-destructor))
    (respawn? #t)))

;;;

(define my-home-environment
  (home-environment
    (packages package-list)
    (services
      (list
        (service home-bash-service-type
                 (home-bash-configuration
                   (guix-defaults? #t)
                   (environment-variables
                     `(("QT_QPA_PLATFORM" . "wayland")
                       ("ECORE_EVAS_ENGINE" . "wayland_egl")
                       ("ELM_ENGINE" . "wayland_egl")
                       ;; Not necessary after sdl2@2.0.22
                       ("SDL_VIDEODRIVER" . "wayland")
                       ;; ("MOZ_ENABLE_WAYLAND" . "1")
                       ;; Work around old qtwebengine and new glibc:
                       ("QTWEBENGINE_CHROMIUM_FLAGS" . "\"--disable-seccomp-filter-sandbox\"")
                       ("EDITOR" . "vim")
                       ("GPG_TTY" . "$(tty)")
                       ("HISTSIZE" . "3000")
                       ("HISTFILESIZE" . "10000")
                       ("HISTCONTROL" . "ignoreboth")
                       ("HISTIGNORE" . "'pwd:exit:fg:bg:top:clear:history:ls:uptime:df'")
                       ("PROMPT_COMMAND" . "\"history -a; $PROMPT_COMMAND\"")))
                   (bash-profile
                     (list
                       (mixed-text-file "bash-profile" "\
unset SSH_AGENT_PID
if [ \"${gnupg_SSH_AUTH_SOCK_by:-0}\" -ne $$ ]; then
    export SSH_AUTH_SOCK=\"$(" (S "gnupg") "/bin/gpgconf --list-dirs agent-ssh-socket)\"
fi
if [ -d ${HOME}/.cache/efreet ]; then
    rm -rf -- ${HOME}/.cache/efreet
fi
if [ -d ${HOME}/.local/share/flatpak/exports/share ]; then
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:${HOME}/.local/share/flatpak/exports/share
fi")))
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

        (service home-shepherd-service-type
                 (home-shepherd-configuration
                   (services
                     (list
                       %syncthing-user-service
                       %dropbox-user-service
                       ;%vdirsyncer-user-service    ; error with 'match'
                       ;%uthsc-vpn-user-service     ; untested
                       ;%mbsync-user-service        ; error with 'match'

                       ;%keybase-user-service       ; won't stay up
                       ;%keybase-fuse-user-service

                       ;%kdeconnect-user-service    ; starts too fast
                       %parcimonie-user-service))))

        (service home-files-service-type
         `(("cvsrc" ,%cvsrc)
           ("gdbinit" ,%gdbinit)
           ("gnupg/gpg.conf" ,%gpg.conf)
           ("gnupg/gpg-agent.conf" ,%gpg-agent.conf)
           ("guile" ,%guile)
           ("inputrc" ,%inputrc)
           ;; Not sure about using this one.
           ; ("mailcap" ,%mailcap)
           ("pbuilderrc" ,%pbuilderrc)
           ("screenrc" ,%screenrc)
           ("signature" ,%signature)
           ("wcalcrc" ,%wcalcrc)
           ("wgetpaste.conf" ,%wgetpaste.conf)
           ("Xdefaults" ,%xdefaults)))

        (service home-xdg-configuration-files-service-type
         `(("aria2/aria2.conf" ,%aria2-config)
           ("git/config" ,%git-config)
           ("git/ignore" ,%git-ignore)
           ("hg/hgrc" ,%hgrc)
           ;; This clears the defaults, do not use.
           ; ("config/lesskey" ,%lesskey)
           ("mpv/scripts/mpris.so"
            ,(file-append (S "mpv-mpris")
                          "/lib/mpris.so"))
           ("mpv/scripts/sponsorblock_minimal.lua"
            ,(file-append (S "mpv-sponsorblock-minimal")
                          "/lib/sponsorblock_minimal.lua"))
           ("mpv/scripts/twitch-chat/main.lua"
            ,(file-append (S "mpv-twitch-chat")
                          "/lib/main.lua"))
           ("mpv/mpv.conf" ,%mpv-conf)
           ("nano/nanorc" ,%nanorc)
           ("streamlink/config" ,%streamlink-config)
           ("youtube-dl/config" ,%ytdl-config)
           ("yt-dlp/config" ,%ytdl-config)))))))

my-home-environment
