(use-modules (guix profiles)
             (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
       '("aria2"
        "aspell"
        "aspell-dict-en"
        "aspell-dict-he"
        "bash-completion"
        "bidiv"
        "borg"
        "btrfs-progs"
        "catimg"
        "emacs"
        "emacs-debbugs"
        "emacs-geiser"
        "emacs-guix"
        "emacs-hydra"
        "ephoto"
        "evisum"
        "ffmpeg"
        "file"
        "font-culmus"
        "font-dejavu"
        "font-gnu-freefont-ttf"
        "font-gnu-unifont"
        "font-terminus"
        "git"
        "git:send-email"
        "git-annex"
        "glibc-utf8-locales"
        "gnupg"
        "gs-fonts"
        "gst-plugins-good"
        "gst-plugins-ugly"
        "icecat"
        "intel-vaapi-driver"
        "isync"
        "kdeconnect"
        "keepassxc"
        "khal"
        "khard"
        "libhdate"
        "libreoffice"
        "links"
        "mosh"
        "mpv"
        "mpv-mpris"
        "msmtp"
        "mutt"
        "my-mcron"
        "my-mupdf"
        "my-pinentry-efl"
        "myrepos"
        "ncdu"
        "netsurf"
        "newsboat"
        "nmap"
        "nss-certs"
        "openssh"
        "parallel"
        "parcimonie"
        "pavucontrol"
        "qrencode"
        "quassel"
        "rsync"
        "rtv"
        "screen"
        "sshfs"
        "stow"
        "syncthing"
        "terminology"
        "tig"
        "tilda"
        "toot"
        "torsocks"
        "translate-shell"
        "tree"
        "urlscan"
        "vdirsyncer"
        "viewnior"
        "vifm"
        "vim"
        "vim-airline"
        "vim-fugitive"
        "wcalc"
        "weechat"
        "wget"
        "wgetpaste"
        "xclip"
        "youtube-dl")))
