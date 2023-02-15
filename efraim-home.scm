(define-module (efraim-home)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu home services ssh)
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

(define %Guix_machines
  (list "bayfront"
        "guixp9"))

(define %UTenn_machines
  (list "lily"
        "penguin2"
        "tux01"
        "tux02"
        "tux03"
        "octopus01"))

(define guix-system?
  (file-exists? "/run/current-system/provenance"))

(define work-machine?
  (not (eq? #f (member (gethostname)
                       (append %Guix_machines
                               %UTenn_machines)))))

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
        "nheko"
        "pavucontrol"
        "qtwayland@5"
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
  (list ))

(define %guix-system-apps
  ;; These packages are provided by Guix System.
  (list "guile"
        "guile-colorized"
        "guile-readline"))

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
        "hunspell-dict-en-us"
        "hunspell-dict-he-il"
        "links"
        "myrepos"
        ;; Currently zig only builds on x86_64-linux but
        ;; is only gated to 64-bit architectures.
        ;(if (package-transitive-supported-systems
        ;      (specification->package "ncdu@2"))
        (if (equal? "x86_64-linux" (%current-system))
          "ncdu@2"
          "ncdu@1")
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
                        (not guix-system?))
                  %headless
                  %GUI-only)
                (if work-machine?
                  %work-applications
                  %not-for-work)
                (if guix-system?
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
      "ytdl-format='bv*[height<=720]+ba/b[height<=720]/bv*[height<=1080]+ba/b[height<1080]/bv+ba/b'\n"
      "gpu-context=wayland\n")))

(define %inputrc
  (plain-file
    "dot-inputrc"
    (string-append
      "set show-mode-in-prompt on\n"
      "set enable-bracketed-paste on\n"
      "set editing-mode vi\n"
      "Control-l: clear-screen\n"
      "set bell-style visible\n"
      "set colored-completion-prefix on\n"
      "set colored-stats on\n")))

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
    "[defaults]\n"
    "log = -v\n"
    "[diff]\n"
    "git = True\n"
    ;"[email]\n"
    ;"method = \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il /usr/lib/dovecot/imap ./Maildir 2> /dev/null\"\n"
    "[ui]\n"
    "username = Efraim Flashner <efraim@flashner.co.il\n"
    "verbose = True\n"
    "merge = meld\n"
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
    "verbose\n"
    "default-stream 720p,720p60,1080p,best\n"
    "player=mpv\n"))

(define %aria2-config
  (plain-file
    "aria2.conf"
    (string-append
      "check-integrity=true\n"
      "max-connection-per-server=5\n"
      "http-accept-gzip=true\n")))

(define %pbuilderrc
  (mixed-text-file
    "dot-pbuilderrc"
    ;; https://wiki.debian.org/PbuilderTricks#How_to_build_for_different_distributions
    "DISTRIBUTION=${DIST:-sid}\n"
    ;; Replace with (%current-system) -> (%debian-system) ?
    "ARCHITECTURE=${ARCH:-$(" (S "dpkg") "/bin/dpkg --print-architecture)}\n"
    "BASETGZ=/var/cache/pbuilder/base-$DISTRIBUTION-$ARCHITECTURE.tgz\n"
    "DEBOOTSTRAPOPTS=( '--arch' $ARCHITECTURE ${DEBOOTSTRAPOPTS[@]} )\n"

    "if [ $ARCHITECTURE == powerpc -o $ARCHITECTURE == riscv64 ]; then\n"
    ;; These are only needed when it's a ports architecture.
    "    MIRRORSITE=http://deb.debian.org/debian-ports\n"
    ;; These two courtesy of John Paul Adrian Glaubitz <glaubitz@physik.fu-berlin.de>
    ;; deb http://incoming.ports.debian.org/buildd/ unstable main|deb http://deb.debian.org/debian-ports unreleased main
    ;; contrib and non-free arch:all packages (i.e. firmware)
    ;; deb [arch=all] http://deb.debian.org/debian/ sid contrib non-free
    "    OTHERMIRROR=\"deb http://incoming.ports.debian.org/buildd/ unstable main|deb http://deb.debian.org/debian-ports unreleased main\"\n"
    "    DEBOOTSTRAPOPTS=( '--keyring' '" (S "debian-ports-archive-keyring") "/share/keyrings/debian-ports-archive-keyring.gpg' ${DEBOOTSTRAPOPTS[@]} )\n"
    "    EXTRAPACKAGES=\"debian-ports-archive-keyring\"\n"
    "fi\n"

    "APTCACHE=/var/cache/apt/archives\n"
    "HOOKDIR=" (getenv "XDG_CONFIG_HOME") "/pbuilder/hooks\n"
    "CCACHEDIR=/var/cache/pbuilder/ccache\n"
    "BINNMU_MAINTAINER=\"Efraim Flashner <efraim@flashner.co.il>\"\n"))

(define %gpg.conf
  (mixed-text-file
    "gpg.conf"
    "default-key CA3D8351\n"
    "display-charset utf-8\n"
    "with-fingerprint\n"
    "keyserver hkp://keyserver.computer42.org\n"
    "keyserver-options auto-key-retrieve\n"
    "keyserver-options include-revoked\n"
    ;"photo-viewer \"" #$(file-append (S "catimg") "/bin/catimg $i\"\n"
    "keyid-format 0xlong\n"
    ;; For use with 'gpg --locate-external-key'
    "auto-key-locate wkd cert pka dane hkp://keys.openpgp.org hkp://keyserver.ubuntu.com hkp://keyserver.computer42.org\n"
    ;; Some of these settings can be seen in g10/keygen.c in gnupg's source code, in keygen_set_std_prefs
    ;; or in the output of `gpg --version`
    ;"personal-cipher-preferences AES256 AES192 AES\n"               ; Drop 3DES
    ;"personal-digest-preferences SHA512 SHA384 SHA256 SHA224\n"     ; Drop SHA1
    ;"cert-digest-algo SHA512\n"
    ;"default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed\n"
    ;"default-cache-ttl 900\n"
    "trust-model tofu+pgp\n"))

;; todo: build gnupg with configure-flags --disable-gpg-idea --disable-gpg-cast5 --disable-gpg-md5 --disable-gpg-rmd160

(define %gpg-agent.conf
  (mixed-text-file
    "gpg-agent.conf"
    #~(if #$guix-system?
        (if #$headless?
          (string-append "pinentry-program " #$(file-append (S "pinentry-tty") "/bin/pinentry-tty") "\n")
          (string-append "pinentry-program " #$(file-append (S "pinentry-efl") "/bin/pinentry-efl") "\n"))
        "pinentry-program /usr/bin/pinentry\n")
    ;"enable-ssh-support\n"
    ;"allow-emacs-pinentry\n"
    ;; This forces signing each commit individually.
    ;"ignore-cache-for-signing\n"
    ))

(define %git-config
  (mixed-text-file
    "git-config"
    "[user]\n"
    "    name = Efraim Flashner\n"
    "    email = efraim@flashner.co.il\n"
    "    signingkey = 0xca3d8351\n"
    "[core]\n"
    "    editor = vim\n"
    "[checkout]\n"
    "    workers = 0\n"             ; Faster on SSDs
    #~(if #$work-machine?
        ""
        (string-append "[commit]\n"
                       "    gpgSign = true\n"))
    "[diff]\n"
    "    algorithm = patience\n"
    "[fetch]\n"
    "    prune = true\n"
    ;"    pruneTags = true\n"
    "    parallel = 0\n"
    "[format]\n"
    "    coverLetter = auto\n"
    "    useAutoBase = whenAble\n"
    "    signatureFile = " %signature "\n"
    "    thread = shallow\n"
    #~(if #$work-machine?
        ""
        (string-append "[gpg]\n"
                       "    program = " #$(file-append (S "gnupg") "/bin/gpg") "\n"))
    "[imap]\n"
    "    folder = Drafts\n"
    "    tunnel = \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il /usr/lib/dovecot/imap ./Maildir 2> /dev/null\"\n"
    ;; This breaks tig
    ;"[log]\n"
    ;"    showSignature = true\n"
    "[pull]\n"
    "    rebase = true\n"
    "[push]\n"
    "   followTags = true\n"
    ;"   gpgSign = if-asked\n"
    "[sendemail]\n"
    "    smtpEncryption = ssl\n"
    #~(if #$work-machine?
        (string-append "    smtpServer = flashner.co.il\n"
                       ;"    smtpsslcertpath = \"\"\n"
        )
        (string-append "    smtpServer = " #$(file-append (S "msmtp") "/bin/msmtp") "\n"))
    "    smtpUser = efraim\n"
    "    smtpPort = 465\n"
    "    supresscc = self\n"
    "    transferEncoding = 8bit\n"
    "    annotate = yes\n"
    "[submodule]\n"
    "    fetchJobs = 0\n"
    "[tag]\n"
    "    gpgSign = true\n"
    "[transfer]\n"
    "    fsckObjects = true\n"
    "[web]\n"
    #~(if (or #$headless? #$work-machine?)
        (string-append "    browser = " #$(file-append (S "links") "/bin/links") "\n")
        ;(string-append "    browser = " #$(file-append (S "netsurf") "/bin/netsurf-gtk3") "\n")
        "    browser = \"qutebrowser --target window\"\n")))

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

(define %qutebrowser-config-py
  (mixed-text-file
    "qutebrowser-config-py"
    ;; "autoconfig.yml is ignored unless it's explicitly loaded\n"
    "config.load_autoconfig(True)\n"
    "config.bind('<Ctrl-Shift-u>', 'spawn --userscript qute-keepassxc --key 0xCA3D8351', mode='insert')\n"
    "config.bind('pw', 'spawn --userscript qute-keepassxc --key 0xCA3D8351', mode='normal')\n"
    "config.bind(',m', 'spawn mpv {url}')\n"
    "config.bind(',M', 'hint links spawn mpv {hint-url}')\n"
    "config.bind(',j', 'jseval (function() {    location.href = \"https://12ft.io/\" + location.href;})();')\n"
    "c.auto_save.session = True\n"
    "c.content.cookies.accept = 'no-3rdparty'\n"
    "c.content.default_encoding = 'utf-8'\n"
    ;"c.content.proxy = 'socks://localhost:9050/'\n"
    ;"c.editor.command = ['terminology', '--exec', 'vim', '-f', '{file}', '-c', 'normal +{line}G+{column0}l']\n"
    "c.editor.command = ['terminology', '--exec', 'vim', '-f', '{file}']\n"
    ;"c.fileselect.folder.command = ['terminology', '--exec', 'ranger', '--choosedir={}']\n"
    ;"c.fileselect.multiple_files.command = ['xterm', '--exec', 'ranger', '--choosefiles={}']\n"
    ;"c.fileselect.single_file.command = ['xterm', '--exec', 'ranger', '--choosefile={}']\n"
    "c.fileselect.folder.command = ['terminology', '--exec', 'vifm', '{}']\n"
    "c.fileselect.multiple_files.command = ['terminology', '--exec', 'vifm', '{}']\n"
    "c.fileselect.single_file.command = ['terminology', '--exec', 'vifm', '{}']\n"
    "c.spellcheck.languages = [\"en-US\", \"he-IL\"]\n"))

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
  (plain-file "gdbinit" "\
# Tell GDB where to look for separate debugging files.
guile
(use-modules (gdb))
(execute (string-append \"set debug-file-directory \"
                        (or (getenv \"GDB_DEBUG_FILE_DIRECTORY\")
                            \"~/.guix-profile/lib/debug\"
                            \"~/.guix-home/profile/lib/debug\")))
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
    "\n"
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
    ;; Use the tunnel instead.
    ;"PassCmd \"" (S "gnupg") "/bin/gpg --quiet --for-your-eyes-only --decrypt $HOME/.msmtp.password.gpg\"\n"
    ;"SSLType IMAPS\n"
    ;"CertificateFile /etc/ssl/certs/ca-certificates.crt\n"
    "Timeout 120\n" ; 25 * 8 / 2
    "Tunnel \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il 'MAIL=maildir:~/Maildir exec /usr/lib/dovecot/imap'\"\n"
    "\n"
    "Channel flashner\n"
    "Far :flashner:\n"
    "Near :local:\n"
    "Patterns * !work\n"))

(define %msmtp-config
  (mixed-text-file
    "msmtp-config"
    "defaults\n"
    "auth            on\n"
    ;; For tor proxy.
    ;"proxy_host     127.0.0.1\n"
    ;"proxy_port     9050\n"
    "tls             on\n"
    "\n"
    ;"flashner.co.il\n"
    "account         flashner.co.il\n"
    "host            flashner.co.il\n"
    "port            465\n"
    "from            efraim@flashner.co.il\n"
    "user            efraim\n"
    ;"passwordeval gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.gpg\n"
    "passwordeval    " (S "gnupg") "/bin/gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.gpg\n"
    "tls_starttls    off\n"
    "tls_fingerprint 49:08:49:DF:A5:E9:73:8F:72:DA:BD:2D:2C:C4:C0:24:34:2B:66:D6\n"
    "\n"
    ;"gmail efraim.flashner\n"
    "account         gmail-efraim\n"
    "host            smtp.gmail.com\n"
    "port            587\n"
    "from            efraim.flashner@gmail.com\n"
    "user            efraim.flashner\n"
    "passwordeval    " (S "gnupg") "/bin/gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.efraimflashnergmail.gpg\n"
    "tls_trust_file  /etc/ssl/certs/ca-certificates.crt\n"
    "\n"
    ;"gmail themillak\n"
    ;"account         gmail-themillak\n"
    ;"host            smtp.gmail.com\n"
    ;"port            587\n"
    ;"from            themillak@gmail.com\n"
    ;"user            themillak\n"
    ;"passwordeval    " (S "gnupg") "/bin/gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.themillakgmail.gpg\n"
    ;"tls_trust_file  /etc/ssl/certs/ca-certificates.crt\n"

    "account default: gmail-efraim\n"))

(define %home-openssh-configuration-hosts
  ;; RemoteForward is "there" to "here".
  (list
    (openssh-host (name "do1-tor")
                  (host-name "ohpdsn5yv7g4gqm3rsz6a323q4ta5vgzptwaje6vkwhobhfwhknd2had.onion"))
    (openssh-host (name "g4-tor")
                  (host-name "km2merla7rtcgknbxk7oiavzh3w6jwmonfgxnruj57tocj3evy4vapad.onion")
                  (extra-content "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra\n"))
    (openssh-host (name "ct-tor")
                  (host-name "teiefezsytzpsennj3ramwqaroh6thqyzdvbu3fxktonvxguqt3rxsid.onion")
                  (identity-file "~/.ssh/id_ed25519")
                  ;(extra-content "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra\n")
                  )
    (openssh-host (name "E5400-tor")
                  (host-name "k27pjetdse4otw2l6qkn5qdqzv3ucuky7jsn4fmibnkxqeleec3yelad.onion")
                  (extra-content "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra\n"))
    (openssh-host (name "3900xt-tor")
                  (host-name "edvqnpr5a2jjuswveoy63k3jxthqpgqatwzk53up5k6ve2rjwgd4jgqd.onion")
                  (extra-content
                    (string-append "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra\n"
                                   "\n\n"
                                   "Include config-work\n")))
    (openssh-host (name "git.sv.gnu.org git.savannah.gnu.org")
                  (identity-file "~/.ssh/id_ed25519_savannah"))
    (openssh-host (name "gitlab.com gitlab.inria.fr salsa.debian.org")
                  (identity-file "~/.ssh/id_ed25519_gitlab"))
    (openssh-host (name "gitlab.gnome.org")
                  (identity-file " ~/.ssh/id_ed25519_gnome"))
    (openssh-host (name "bayfront")
                  (host-name "bayfront.guix.gnu.org")
                  (identity-file "~/.ssh/id_ed25519_overdrive")
                  (compression? #t)
                  (extra-content "  RemoteForward /home/efraim/.gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra\n"))
    (openssh-host (name "guixp9")
                  (host-name "p9.tobias.gr")
                  (identity-file "~/.ssh/id_ed25519_overdrive"))
    (openssh-host (name "*.onion *-tor")
                  (compression? #t)
                  ;; Either this or we always need to prefix with torsocks.
                  ;; TODO: Replace the custom ~/bin/openbsd-netcat with the line below:
                  ;(proxy-command (string-append (S "netcat-openbsd") "/bin/nc -X 5 -x localhost:9050 %h %p"))
                  (proxy-command (string-append (getenv "HOME") "/bin/openbsd-netcat -X 5 -x localhost:9050 %h %p"))
                  (extra-content "  ControlPath ${XDG_RUNTIME_DIR}/%r@%k-%p\n"))
    (openssh-host (name "*")
                  (user "efraim")
                  (extra-content
                    (string-append "  ControlMaster auto\n"
                                   "  ControlPath ${XDG_RUNTIME_DIR}/%r@%h-%p\n"
                                   "  ControlPersist 600\n")))))

;;; Executables for the $HOME/bin folder.

(define %connect-to-UTHSC-VPN
  (program-file
    "GN_vpn_connect"
    #~(system*
        #$(file-append (S "dbus") "/bin/dbus-launch")
        #$(file-append (S "openconnect-sso") "/bin/openconnect-sso")
        "--server" "uthscvpn1.uthsc.edu" "--authgroup" "UTHSC"
        "--" "--script"
        ;; This needs to be one string but I can't get it to work correctly.
        ;#$(string-append "'"
        ;                 (file-append (S "vpn-slice") "/bin/vpn-slice")
                         #$(file-append (S "vpn-slice") "/bin/vpn-slice")
                         "128.169.0.0/16"
        ;                 "'")
        )))

;;; Extra services.

(define %syncthing-user-service
  (shepherd-service
    (documentation "Run `syncthing' without calling the browser")
    (provision '(syncthing))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "syncthing") "/bin/syncthing")
                     "-no-browser")
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/syncthing.log")))
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
                     (string-append (getenv "HOME") "/Dropbox"))
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/dbxfs.log")))
    (stop #~(make-system-destructor
              (string-append "fusermount -u " (getenv "HOME") "/Dropbox")))
    ;; Needs gpg key to unlock
    (auto-start? #f)
    (respawn? #f)))

;; This needs more work with user shepherd services.
(define %vdirsyncer-user-service
 ;; Doesn't get imported into the gexp.
 ;(with-imported-modules '((ice-9 match))
  (shepherd-service
    (documentation "Run vdirsyncer hourly")
    (provision '(vdirsyncer))
    (start
      #~(lambda args
          ;; Doesn't go in the background.
          (use-modules (ice-9 match))
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
    (respawn? #t)));)

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
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/keybase.log")))
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
                     "-log-to-file")
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/kbfs.log")))
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
               (list #$(file-append (S "dbus") "/bin/dbus-launch")
                     #$(file-append (S "kdeconnect") "/libexec/kdeconnectd")
                     "-platform" "offscreen")
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/kdeconnect.log")))
    ;; TODO: Enable autostart
    (auto-start? #f)
    (stop #~(make-kill-destructor))))

(define %parcimonie-user-service
  (shepherd-service
    (documentation "Incrementally refresh gnupg keyring")
    (provision '(parcimonie))
    (start #~(make-forkexec-constructor
               ;(use-modules (srfi srfi-26))
               (list #$(file-append (S "parcimonie") "/bin/parcimonie")
                     ;; Can I use compose and find or a list to make this work?
                     ;(map (cut compose list "--gnupg_extra_args" string-append "--keyring=" <>)
                     ;     (find-files (getenv "XDG_CONFIG_HOME") "^trustedkeys\\.kbx$")))
                     "--gnupg_extra_args"
                     (string-append "--keyring="
                                    (getenv "XDG_CONFIG_HOME")
                                    "/guix/upstream/trustedkeys.kbx")
                     "--gnupg_extra_args"
                     (string-append "--keyring="
                                    (getenv "XDG_CONFIG_HOME")
                                    "/guix/gpg/trustedkeys.kbx"))
               #:log-file (string-append (getenv "XDG_LOG_HOME") "/parcimonie.log")))
    (stop #~(make-kill-destructor))
    (respawn? #t)))

;;;

(define guix-system-home-environment
  (home-environment
    (packages package-list)
    (services
      (list
        (service home-bash-service-type
                 (home-bash-configuration
                   (guix-defaults? #t)
                   (environment-variables
                    `(;("QT_QPA_PLATFORM" . "wayland")
                      ("ECORE_EVAS_ENGINE" . "wayland_egl")
                      ("ELM_ENGINE" . "wayland_egl")
                      ;; Still necessary for sdl2@2.0.14
                      ("SDL_VIDEODRIVER" . "wayland")
                      ("GDK_BACKEND" . "wayland")
                      ;; Still causing trouble :/
                      ;("MOZ_ENABLE_WAYLAND" . "1")
                      ;; Work around qtwebengine and glibc issues:
                      ;; Still necessary with qtwebengine-5.15.5, no text on ci.guix.gnu.org.
                      ("QTWEBENGINE_CHROMIUM_FLAGS" . "--disable-seccomp-filter-sandbox")
                      ;; Append guix-home directories to bash completion dirs.
                      ("BASH_COMPLETION_USER_DIR" .
                       ,(string-append "$BASH_COMPLETION_USER_DIR:"
                                       "$HOME/.guix-home/profile/share/bash-completion/completions:"
                                       "$HOME/.guix-home/profile/etc/bash_completion.d"))
                      ("CVS_RSH" . "ssh")
                      ("EDITOR" . "vim")
                      ("GPG_TTY" . "$(tty)")
                      ("XZ_DEFAULTS" . "--threads=0 --memlimit=50%")
                      ("HISTSIZE" . "3000")
                      ("HISTFILESIZE" . "10000")
                      ("HISTCONTROL" . "ignoreboth")
                      ("HISTIGNORE" . "pwd:exit:fg:bg:top:clear:history:ls:uptime:df")
                      ("PROMPT_COMMAND" . "history -a; $PROMPT_COMMAND")))
                   (aliases
                    `(("cp" . "cp --reflink=auto")
                      ("exitexit" . "exit")
                      ("clear" . "printf '\\E[H\\E[J\\E[0m'")
                      ("ime" . "time")
                      ("guix-home-build" .
                       ,(string-append "~/workspace/guix/pre-inst-env guix home "
                                       "build --no-grafts --fallback "
                                       "-L ~/workspace/my-guix/ "
                                       "~/workspace/guix-config/efraim-home.scm"))
                      ("guix-home-reconfigure" .
                       ,(string-append "~/workspace/guix/pre-inst-env guix home "
                                       "reconfigure --fallback "
                                       "-L ~/workspace/my-guix/ "
                                       "~/workspace/guix-config/efraim-home.scm"))))
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
fi")))))

        (service home-shepherd-service-type
                 (home-shepherd-configuration
                   (services
                     (list
                       %syncthing-user-service
                       %dropbox-user-service
                       ;%vdirsyncer-user-service    ; error with 'match'
                       ;%mbsync-user-service        ; error with 'match'

                       %keybase-user-service
                       %keybase-fuse-user-service

                       %kdeconnect-user-service
                       %parcimonie-user-service))))

        ;(service home-openssh-service-type
        ;         (home-openssh-configuration
        ;           (hosts %home-openssh-configuration-hosts)))

        (service home-files-service-type
         `((".cvsrc" ,%cvsrc)
           (".gnupg/gpg.conf" ,%gpg.conf)
           (".gnupg/gpg-agent.conf" ,%gpg-agent.conf)
           (".guile" ,%guile)
           (".inputrc" ,%inputrc)
           ;; Not sure about using this one.
           ; (".mailcap" ,%mailcap)
           (".mbsyncrc" ,%mbsyncrc)
           (".pbuilderrc" ,%pbuilderrc)
           (".screenrc" ,%screenrc)
           (".signature" ,%signature)
           (".wcalcrc" ,%wcalcrc)
           (".wgetpaste.conf" ,%wgetpaste.conf)
           (".Xdefaults" ,%xdefaults)

           ;; Also files into the bin directory.
           ("bin/GN_vpn_connect" ,%connect-to-UTHSC-VPN)
           ("bin/openbsd-netcat" ,(file-append (S "netcat-openbsd") "/bin/nc"))))

        (service home-xdg-configuration-files-service-type
         `(("aria2/aria2.conf" ,%aria2-config)
           ("gdb/gdbinit" ,%gdbinit)
           ("git/config" ,%git-config)
           ("git/ignore" ,%git-ignore)
           ("hg/hgrc" ,%hgrc)
           ;; This clears the defaults, do not use.
           ; ("config/lesskey" ,%lesskey)
           ("mpv/scripts/mpris.so"
            ,(file-append (S "mpv-mpris")
                          "/lib/mpris.so"))
           ("mpv/scripts/sponsorblock_minimal/main.lua"
            ,(file-append (S "mpv-sponsorblock-minimal")
                          "/lib/sponsorblock_minimal.lua"))
           ("mpv/scripts/twitch-chat/main.lua"
            ,(file-append (S "mpv-twitch-chat")
                          "/lib/main.lua"))
           ("mpv/mpv.conf" ,%mpv-conf)
           ("msmtp/config" ,%msmtp-config)
           ("nano/nanorc" ,%nanorc)
           ("qutebrowser/config.py" ,%qutebrowser-config-py)
           ("streamlink/config" ,%streamlink-config)
           ("youtube-dl/config" ,%ytdl-config)
           ("yt-dlp/config" ,%ytdl-config)))))))

(define foreign-home-environment
  (home-environment
    (packages package-list)
    (services
      (list
        (service home-files-service-type
         `((".cvsrc" ,%cvsrc)
           ;(".gnupg/gpg.conf" ,%gpg.conf)
           ;(".gnupg/gpg-agent.conf" ,%gpg-agent.conf)
           (".guile" ,%guile)
           (".inputrc" ,%inputrc)
           ;; Not sure about using this one.
           ; (".mailcap" ,%mailcap)
           (".mbsyncrc" ,%mbsyncrc)
           ;(".pbuilderrc" ,%pbuilderrc)
           (".screenrc" ,%screenrc)
           (".signature" ,%signature)
           (".wcalcrc" ,%wcalcrc)
           (".wgetpaste.conf" ,%wgetpaste.conf)
           ;(".Xdefaults" ,%xdefaults)

           ;; Also files into the bin directory.
           ("bin/GN_vpn_connect" ,%connect-to-UTHSC-VPN)
           ;("bin/openbsd-netcat" ,(file-append (S "netcat-openbsd") "/bin/nc"))
           ))

        (service home-xdg-configuration-files-service-type
         `(("aria2/aria2.conf" ,%aria2-config)
           ("gdb/gdbinit" ,%gdbinit)
           ("git/config" ,%git-config)
           ("git/ignore" ,%git-ignore)
           ("hg/hgrc" ,%hgrc)
           ;; This clears the defaults, do not use.
           ; ("config/lesskey" ,%lesskey)
           ("mpv/scripts/mpris.so"
            ,(file-append (S "mpv-mpris")
                          "/lib/mpris.so"))
           ("mpv/scripts/sponsorblock_minimal/main.lua"
            ,(file-append (S "mpv-sponsorblock-minimal")
                          "/lib/sponsorblock_minimal.lua"))
           ("mpv/scripts/twitch-chat/main.lua"
            ,(file-append (S "mpv-twitch-chat")
                          "/lib/main.lua"))
           ("mpv/mpv.conf" ,%mpv-conf)
           ("msmtp/config" ,%msmtp-config)
           ;; Specific to Guix System
           ;("nano/nanorc" ,%nanorc)
           ;("qutebrowser/config.py" ,%qutebrowser-config-py)
           ("streamlink/config" ,%streamlink-config)
           ("youtube-dl/config" ,%ytdl-config)
           ("yt-dlp/config" ,%ytdl-config)))))))

(if guix-system?
  guix-system-home-environment
  foreign-home-environment)
