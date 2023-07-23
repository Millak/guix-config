(define-module (efraim-home)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services mail)
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

;; To create a temporary directory in XDG_RUNTIME_DIR
;; (mkdtemp (string-append (getenv "XDG_RUNTIME_DIR") "/XXXXXX"))

(define %logdir
  (string-append
    (or (getenv "XDG_STATE_HOME")
        (string-append (getenv "HOME") "/.local/state"))
    "/log"))

(define headless?
  (eq? #f (getenv "DISPLAY")))

(define %Guix_machines
  (list "bayfront"
        "berlin"
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
        "alacritty"
        "font-culmus"
        "font-dejavu"
        "font-ghostscript"
        "font-gnu-freefont"
        "font-gnu-unifont"
        "font-opendyslexic"
        "font-terminus"
        "flatpak"
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-ugly"
        "i3status"
        "icecat"
        "imv"           ; this or qiv
        "kdeconnect"
        "keepassxc"
        "lagrange"
        "libnotify"     ; notify-send
        "libreoffice"
        "mpv"
        "mupdf"
        "my-moreutils"
        "nheko"
        "pavucontrol"
        "qiv"           ; this or imv
        "qtwayland@5"
        "quasselclient"
        "qutebrowser"
        "telegram-desktop"
        "tofi"
        "tuba"
        "wl-clipboard-x11"
        "xdg-desktop-portal"
        "xdg-desktop-portal-wlr"
        "zathura"
        "zathura-pdf-poppler"))

(define %work-applications
  (list "diffoscope"
        "mercurial"
        "strace"))

(define %not-for-work
  (list "btrfs-progs"
        "ffmpeg"
        "git-annex"
        "isync"
        ;"keybase"
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
        "yt-dlp"))

(define %headless
  (list "weechat"))

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
        ;(if (supported-package? (specification->package "ncdu@2"))
        (if (equal? "x86_64-linux" (%current-system))
          "ncdu@2"
          "ncdu@1")
        "nmap"
        "nss-certs"
        "openssh"
        "parallel"
        "python-codespell"
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

;;

(define S specification->package)

(define package-list
  (map (compose list specification->package+output)
       (filter (lambda (pkg)
                 (supported-package?
                   (specification->package+output pkg)))
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
      ;; C-V U 0 0 A 0 is a non-breaking space, like below:
      ;; NB: C-V U 2 0 0 F is a right-to-left mark, C-V U 2 0 0 E is a left-to-right mark.
      ;; https://en.wikipedia.org/wiki/Bidirectional_text
      ;"Efraim Flashner   <efraim@flashner.co.il>   פלשנר אפרים\n"
      "Efraim Flashner   <efraim@flashner.co.il>   רנשלפ םירפא\n"
      ;"Efraim Flashner   <efraim@flashner.co.il>   אפרים פלשנר\n"
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
    ;; This one caused `pbuilder create` failures on real ppc hardware.
    ;"    OTHERMIRROR=\"deb http://incoming.ports.debian.org/buildd/ unstable main|deb http://deb.debian.org/debian-ports unreleased main\"\n"
    "    DEBOOTSTRAPOPTS=( '--keyring' '" (S "debian-ports-archive-keyring") "/share/keyrings/debian-ports-archive-keyring.gpg' '--arch' $ARCHITECTURE ${DEBOOTSTRAPOPTS[@]} )\n"
    "    EXTRAPACKAGES=\"debian-ports-archive-keyring\"\n"
    "fi\n"

    "APTCACHE=/var/cache/apt/archives\n"    ; Same as apt itself.
    "HOOKDIR=" (or (getenv "XDG_CONFIG_HOME")
                   (string-append (getenv "HOME") "/.config")) "/pbuilder/hooks\n"
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
    ;"photo-viewer \"" #$(file-append (S "imv") "/bin/imv $i\"\n"
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
          (string-append "pinentry-program " #$(file-append (S "pinentry-qt") "/bin/pinentry-qt") "\n"))
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
    "    signingkey = 0xCA3D8351\n"
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
    "    recurse = true\n"
    "[tag]\n"
    "    gpgSign = true\n"
    "[transfer]\n"
    "    fsckObjects = true\n"
    "[web]\n"
    #~(if (or #$headless? #$work-machine?)
        (string-append "    browser = " #$(file-append (S "links") "/bin/links") "\n")
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

(define %newsboat-config
  (mixed-text-file
    "newsboat-config"
    "browser \"qutebrowser --target window %u\"\n"
    "download-full-page yes\n"
    "article-sort-order date-desc\n"
    "save-path \"~/Downloads\"\n"
    "auto-reload yes\n"
    "reload-threads 3\n"
    "download-retries 5\n"
    ;"max-items 200\n"
    ;"keep-articles-days 180\n"
    "download-path \"~/Downloads/\"\n"
    "max-downloads 2\n"
    ;"bind-key ^R reload-all\n"
    "prepopulate-query-feeds yes\n"
    "suppress-first-reload yes\n"
    ;"proxy localhost:9050\n"
    ;"proxy-type socks5\n"
    ;"use-proxy yes\n"
    "download-timeout 90\n"))

(define %qutebrowser-config-py
  (mixed-text-file
    "qutebrowser-config-py"
    ;; "autoconfig.yml is ignored unless it's explicitly loaded\n"
    "config.load_autoconfig(True)\n"
    "config.bind('<Ctrl-Shift-u>', 'spawn --userscript qute-keepassxc --key 0xCA3D8351', mode='insert')\n"
    "config.bind('pw', 'spawn --userscript qute-keepassxc --key 0xCA3D8351', mode='normal')\n"
    "config.bind('pt', 'spawn --userscript qute-keepassxc --key 0xCA3D8351 --totp', mode='normal')\n"
    "config.bind(',m', 'spawn mpv {url}')\n"
    "config.bind(',M', 'hint links spawn mpv {hint-url}')\n"
    "config.bind(',j', 'jseval (function() {    location.href = \"https://12ft.io/\" + location.href;})();')\n"
    "c.auto_save.session = True\n"
    "c.content.cookies.accept = 'no-3rdparty'\n"
    "c.content.default_encoding = 'utf-8'\n"
    "c.content.pdfjs = True\n"
    ;"c.content.proxy = 'socks://localhost:9050/'\n"
    ;"c.editor.command = ['alacritty', '--command', 'vim', '-f', '{file}', '-c', 'normal +{line}G+{column0}l']\n"
    "c.editor.command = ['alacritty', '--command', 'vim', '-f', '{file}']\n"
    ;"c.fileselect.folder.command = ['xterm', '--exec', 'ranger', '--choosedir={}']\n"
    ;"c.fileselect.multiple_files.command = ['xterm', '--exec', 'ranger', '--choosefiles={}']\n"
    ;"c.fileselect.single_file.command = ['xterm', '--exec', 'ranger', '--choosefile={}']\n"
    "c.fileselect.folder.command = ['alacritty', '--command', 'vifm', '{}']\n"
    "c.fileselect.multiple_files.command = ['alacritty', '--command', 'vifm', '{}']\n"
    "c.fileselect.single_file.command = ['alacritty', '--command', 'vifm', '{}']\n"
    "c.spellcheck.languages = [\"en-US\", \"he-IL\"]\n"))

(define %gdbinit
  (plain-file "gdbinit" "\
# Tell GDB where to look for separate debugging files.
guile
(use-modules (gdb))
(execute (string-append \"set debug-file-directory \"
                        (string-join
                          (filter file-exists?
                                  (append
                                    (if (getenv \"GDB_DEBUG_FILE_DIRECTORY\")
                                      (list (getenv \"GDB_DEBUG_FILE_DIRECTORY\"))
                                      '())
                                    (list \"~/.guix-home/profile/lib/debug\"
                                          \"~/.guix-profile/lib/debug\"
                                          \"/run/current-system/profile/lib/debug\")))
                          \":\")))
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
    ;"MapInbox INBOX\n"
    ;"Trash Trash\n"
    "Flatten .\n"
    ;"SubFolders Verbatim\n"
    "\n"
    "IMAPStore flashner\n"
    "Host flashner.co.il\n"
    ;; Use the tunnel instead.
    ;"PassCmd \"" (S "gnupg") "/bin/gpg --quiet --for-your-eyes-only --decrypt $HOME/.msmtp.password.gpg\"\n"
    ;"SSLType IMAPS\n"
    ;"CertificateFile /etc/ssl/certs/ca-certificates.crt\n"
    "Timeout 120\n" ; 25 MB * 8 (bytes to bits) / 2 Mb/s = 100 s, add 20% for safety.
    "Tunnel \"" (S "openssh") "/bin/ssh -o Compression=yes -q flashner.co.il 'MAIL=maildir:~/Maildir exec /usr/lib/dovecot/imap'\"\n"
    "\n"
    "Channel flashner\n"
    "Far :flashner:\n"
    "Near :local:\n"
    "Patterns * !work\n"))

(define %home-inputrc-configuration
  (home-inputrc-configuration
  (key-bindings
    `(("Control-l" . "clear-screen")))  ; would I rather have clear-display?
  (variables
    `(("bell-style" . "visible")
      ("colored-completion-prefix" . #t)
      ("colored-stats" . #t)
      ("enable-bracketed-paste" . #t)
      ("editing-mode" . "vi")
      ("show-mode-in-prompt" . #t)))))

(define %home-msmtp-configuration-accounts
  (list
    (msmtp-account
      (name "flashner.co.il")
      (configuration
        (msmtp-configuration
          (host "flashner.co.il")
          (port 465)
          (user "efraim")
          (from "efraim@flashner.co.il")
          (password-eval "gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.gpg")
          (tls-starttls? #f)
          (extra-content "tls_fingerprint 49:08:49:DF:A5:E9:73:8F:72:DA:BD:2D:2C:C4:C0:24:34:2B:66:D6"))))
    (msmtp-account
      (name "gmail-efraim")
      (configuration
        (msmtp-configuration
          (host "smtp.gmail.com")
          (port 587)
          (user "efraim.flashner")
          (from "efraim.flashner@gmail.com")
          (password-eval "gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.efraimflashnergmail.gpg")
          (tls-trust-file "/etc/ssl/certs/ca-certificates.crt"))))
    (msmtp-account
      (name "gmail-themillak")
      (configuration
        (msmtp-configuration
          (host "smtp.gmail.com")
          (port 587)
          (user "themillak")
          (from "themillak@gmail.com")
          (password-eval "gpg --no-tty --for-your-eyes-only --quiet --decrypt $HOME/.msmtp.password.themillakgmail.gpg")
          (tls-trust-file "/etc/ssl/certs/ca-certificates.crt"))))))

(define %home-openssh-configuration-hosts
  ;; RemoteForward is "remote/there" to "local/here".
  ;; LocalForward is "local/here" to "remote/there".
  (list
    (openssh-host (name "*")
                  ;; Need to put something for HOST or MATCH before I can put the Include.
                  (extra-content "Include config-uthsc\n"))
    (openssh-host (name "do1-tor")
                  (host-name "ohpdsn5yv7g4gqm3rsz6a323q4ta5vgzptwaje6vkwhobhfwhknd2had.onion"))
    #;(openssh-host (name "do1")
                  (host-name "flashner.co.il")
                  (extra-content "  LocalForward localhost:3000 flashner.co.il:3000\n"))
    (openssh-host (name "g4-tor")
                  (host-name "km2merla7rtcgknbxk7oiavzh3w6jwmonfgxnruj57tocj3evy4vapad.onion")
                  (extra-content "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/$i/gnupg/S.gpg-agent.extra\n"))
    (openssh-host (name "ct-tor")
                  (host-name "teiefezsytzpsennj3ramwqaroh6thqyzdvbu3fxktonvxguqt3rxsid.onion")
                  (identity-file "~/.ssh/id_ed25519"))
    (openssh-host (name "E5400-tor")
                  (host-name "k27pjetdse4otw2l6qkn5qdqzv3ucuky7jsn4fmibnkxqeleec3yelad.onion")
                  (extra-content "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/$i/gnupg/S.gpg-agent.extra\n"))
    (openssh-host (name "3900xt-tor")
                  (host-name "edvqnpr5a2jjuswveoy63k3jxthqpgqatwzk53up5k6ve2rjwgd4jgqd.onion")
                  (extra-content "  RemoteForward /run/user/1000/gnupg/S.gpg-agent /run/user/$i/gnupg/S.gpg-agent.extra\n"))
    (openssh-host (name "hetzner-storage")
                  (host-name "u353806.your-storagebox.de")
                  (user "u353806-sub2")
                  (port 23)
                  (identity-file "~/.ssh/id_ed25519"))
    (openssh-host (name "git.sv.gnu.org git.savannah.gnu.org")
                  (identity-file "~/.ssh/id_ed25519_savannah"))
    (openssh-host (name "gitlab.com gitlab.inria.fr salsa.debian.org")
                  (identity-file "~/.ssh/id_ed25519_gitlab"))
    (openssh-host (name "gitlab.gnome.org")
                  (identity-file " ~/.ssh/id_ed25519_gnome"))
    (openssh-host (name "berlin")
                  (host-name "berlin.guix.gnu.org")
                  (identity-file "~/.ssh/id_ed25519_overdrive"))
    #;(openssh-host (name "bayfront")
                  (host-name "bayfront.guix.gnu.org")
                  (identity-file "~/.ssh/id_ed25519_overdrive"))
    (openssh-host (name "guixp9")
                  (host-name "p9.tobias.gr")
                  (identity-file "~/.ssh/id_ed25519_overdrive"))
    #;(openssh-host (name "*.unicorn-typhon.ts.net")
                  (proxy
                    (list
                      (proxy-jump (host-name "do1")))))
    (openssh-host (name "*.onion *-tor")
                  (compression? #t)
                  (proxy
                    ;; Either this or we always need to prefix with torsocks.
                    ;; TODO: Replace the custom ~/bin/openbsd-netcat with the line below:
                    ;(proxy-command (string-append (S "netcat-openbsd") "/bin/nc -X 5 -x localhost:9050 %h %p")))
                    (proxy-command (string-append (getenv "HOME") "/bin/openbsd-netcat -X 5 -x localhost:9050 %h %p")))
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

(define %update-guix-gpg-keyring
  (program-file
    "update-guix-members-gpg-keys"
    #~(let ((gpg-keyring (tmpnam))
            (keyring-file "https://savannah.gnu.org/project/memberlist-gpgkeys.php?group=guix&download=1"))
        ((@ (guix build download) url-fetch) keyring-file gpg-keyring)
        (system* "gpg" "--import" gpg-keyring)
        ;; Clean up after ourselves.
        (delete-file gpg-keyring))))

;;; Extra services.

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
                     (string-append (getenv "HOME") "/Dropbox"))
               #:log-file (string-append #$%logdir "/dbxfs.log")))
    (stop #~(make-system-destructor
              (string-append "fusermount -u " (getenv "HOME") "/Dropbox")))
    ;; Needs gpg key to unlock.
    (auto-start? #f)
    (respawn? #f)))

(define %onedrive-user-service
  (shepherd-service
    (documentation "Provide access to Onedrive™")
    (provision '(onedrive))
    (start #~(make-forkexec-constructor
               (list #$(file-append (S "onedrive") "/bin/onedrive")
                     "--monitor"
                     "--verbose"
                     (string-append (getenv "HOME") "/Onedrive"))
               #:log-file (string-append #$%logdir "/onedrive.log")))
    (stop #~(make-system-destructor
              (string-append "fusermount -u " (getenv "HOME") "/Onedrive")))
    (auto-start? #f)        ; Needs network.
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
               #:log-file (string-append #$%logdir "/keybase.log")))
    (stop #~(make-system-destructor
              (string-append #$(file-append (S "keybase")
                                            "/bin/keybase")
                             " ctl stop")))
    ;; Starts too fast at login.
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
               #:log-file (string-append #$%logdir "/kbfs.log")))
    (stop #~(make-kill-destructor))
    ;; Depends on keybase.
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
                     ;; KDE Connect was built without "offscreen" support
                     ;; without this it fails to create wl_display
                     "-platform" "offscreen")
               #:log-file (string-append #$%logdir "/kdeconnect.log")))
    ;; TODO: Enable autostart
    (auto-start? #f)
    (stop #~(make-kill-destructor))))

(define %parcimonie-user-service
  (shepherd-service
    (documentation "Incrementally refresh gnupg keyring over Tor")
    (provision '(parcimonie))
    (start #~(make-forkexec-constructor
               #;(use-modules (guix build utils)
                            (srfi srfi-1))
               (list #$(file-append (S "parcimonie") "/bin/parcimonie")
                     #;(append-map (lambda (item)
                             (list "--gnupg_extra_options" "--keyring" item))
                           (find-files (getenv "XDG_CONFIG_HOME") "^trustedkeys\\.kbx$"))
                     ;; returns: ("--gnupg_extra_options" "--keyring" "/home/efraim/.config/guix/gpg/trustedkeys.kbx" "--gnupg_extra_options" "--keyring" "/home/efraim/.config/guix/upstream/trustedkeys.kbx")
                     ;; Needs to not be a list inside of a list.
                     "--gnupg_extra_args"
                     (string-append "--keyring="
                                    (or (getenv "XDG_CONFIG_HOME")
                                        (string-append (getenv "HOME") "/.config"))
                                    "/guix/upstream/trustedkeys.kbx")
                     "--gnupg_extra_args"
                     (string-append "--keyring="
                                    (or (getenv "XDG_CONFIG_HOME")
                                        (string-append (getenv "HOME") "/.config"))
                                    "/guix/gpg/trustedkeys.kbx"))
               #:log-file (string-append #$%logdir "/parcimonie.log")))
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
                    `(("QT_QPA_PLATFORM" . "wayland")
                      ("ECORE_EVAS_ENGINE" . "wayland_egl")
                      ("ELM_ENGINE" . "wayland_egl")
                      ;; Still necessary for sdl2@2.0.14
                      ("SDL_VIDEODRIVER" . "wayland")
                      ("GDK_BACKEND" . "wayland")
                      ("MOZ_ENABLE_WAYLAND" . "1")

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
                      ;("clear" . ,(file-append (S "ncurses") "/bin/clear"))
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
if [ -d ${XDG_DATA_HOME}/flatpak/exports/share ]; then
    export XDG_DATA_DIRS=$XDG_DATA_DIRS:${XDG_DATA_HOME}/flatpak/exports/share
fi")))))

        (service home-shepherd-service-type
                 (home-shepherd-configuration
                   (services
                     (list
                       %syncthing-user-service
                       %dropbox-user-service
                       ;%vdirsyncer-user-service    ; error with 'match'
                       ;%mbsync-user-service        ; error with 'match'

                       ;%keybase-user-service
                       ;%keybase-fuse-user-service

                       %kdeconnect-user-service
                       %parcimonie-user-service))))

        ;; Can't seem to get (if headless?) to work
        #;(service home-gpg-agent-service-type
                 (home-gpg-agent-configuration
                   (gnupg
                     (if headless?
                       (file-append (S "pinentry-tty") "/bin/pinentry-tty")
                       (file-append (S "pinentry-qt") "/bin/pinentry-qt")))))

        (service home-inputrc-service-type
                   %home-inputrc-configuration)

        (service home-msmtp-service-type
                 (home-msmtp-configuration
                   (default-account "gmail-efraim")
                   (defaults
                     (msmtp-configuration
                       ;; For tor proxy.
                       #;(extra-content
                         (string-append "proxy_host 127.0.0.1\n"
                                        "proxy_port 9050"))
                       (auth? #t)
                       (tls? #t)))
                   (accounts %home-msmtp-configuration-accounts)))

        (service home-openssh-service-type
                 (home-openssh-configuration
                   (hosts %home-openssh-configuration-hosts)))

        (service home-files-service-type
         `((".cvsrc" ,%cvsrc)
           (".gnupg/gpg.conf" ,%gpg.conf)
           (".gnupg/gpg-agent.conf" ,%gpg-agent.conf)
           (".guile" ,%guile)
           ;; Not sure about using this one.
           ; (".mailcap" ,%mailcap)
           (".mbsyncrc" ,%mbsyncrc)
           (".pbuilderrc" ,%pbuilderrc)
           (".screenrc" ,%screenrc)
           (".signature" ,%signature)
           (".wcalcrc" ,%wcalcrc)
           (".wgetpaste.conf" ,%wgetpaste.conf)
           (".Xdefaults" ,%xdefaults)

           (".local/share/qutebrowser/pdfjs"
            ,(file-append (S "pdfjs-legacy") "/share/pdfjs"))
           ;; Also files into the bin directory.
           ;("bin/GN_vpn_connect" ,%connect-to-UTHSC-VPN)
           ;("bin/msmtp-password-flashner" ,%email-password)
           ("bin/update-guix-keyring" ,%update-guix-gpg-keyring)
           ("bin/openbsd-netcat"
            ,(file-append (S "netcat-openbsd") "/bin/nc"))))

        (service home-xdg-configuration-files-service-type
         `(("aria2/aria2.conf" ,%aria2-config)
           #;("chromium/WidevineCdm/latest-component-updated-widevine-cdm"
            ,(file-append (S "widevine")
                          "/share/chromium/latest-component-updated-widevine-cdm"))
           ("gdb/gdbinit" ,%gdbinit)
           ("git/config" ,%git-config)
           ("git/ignore" ,%git-ignore)
           ("hg/hgrc" ,%hgrc)
           ;; This clears the defaults, do not use.
           ; ("lesskey" ,%lesskey)
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
           ("newsboat/config" ,%newsboat-config)
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

        (service home-inputrc-service-type
                   %home-inputrc-configuration)

        (service home-msmtp-service-type
                 (home-msmtp-configuration
                   (default-account "gmail-efraim")
                   (defaults
                     (msmtp-configuration
                       ;; For tor proxy.
                       #;(extra-content
                         (string-append "proxy_host 127.0.0.1\n"
                                        "proxy_port 9050"))
                       (auth? #t)
                       (tls? #t)))
                   (accounts %home-msmtp-configuration-accounts)))

        (service home-files-service-type
         `((".cvsrc" ,%cvsrc)
           ;(".gnupg/gpg.conf" ,%gpg.conf)
           ;(".gnupg/gpg-agent.conf" ,%gpg-agent.conf)
           (".guile" ,%guile)
           ;; Not sure about using this one.
           ; (".mailcap" ,%mailcap)
           (".mbsyncrc" ,%mbsyncrc)
           ;(".pbuilderrc" ,%pbuilderrc)
           (".screenrc" ,%screenrc)
           (".signature" ,%signature)
           (".wcalcrc" ,%wcalcrc)
           (".wgetpaste.conf" ,%wgetpaste.conf)
           ;(".Xdefaults" ,%xdefaults)

           (".local/share/qutebrowser/pdfjs"
            ,(file-append (S "pdfjs") "/share/pdfjs"))
           ;; Also files into the bin directory.
           ;("bin/GN_vpn_connect" ,%connect-to-UTHSC-VPN)
           ("bin/openbsd-netcat"
            ,(file-append (S "netcat-openbsd") "/bin/nc"))))

        (service home-xdg-configuration-files-service-type
         `(("aria2/aria2.conf" ,%aria2-config)
           ("gdb/gdbinit" ,%gdbinit)
           ("git/config" ,%git-config)
           ("git/ignore" ,%git-ignore)
           ("hg/hgrc" ,%hgrc)
           ;; This clears the defaults, do not use.
           ; ("lesskey" ,%lesskey)
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
           ("newsboat/config" ,%newsboat-config)
           ;; Specific to Guix System
           ;("nano/nanorc" ,%nanorc)
           ;("qutebrowser/config.py" ,%qutebrowser-config-py)
           ("streamlink/config" ,%streamlink-config)
           ("youtube-dl/config" ,%ytdl-config)
           ("yt-dlp/config" ,%ytdl-config)))))))

(if guix-system?
  guix-system-home-environment
  foreign-home-environment)
