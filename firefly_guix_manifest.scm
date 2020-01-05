(use-modules (guix profiles)
             (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
       '("aria2"
        "bash-completion"
        "borg"
        "catimg"
        "file"
        "git"
        "git:send-email"
        "glibc-utf8-locales"
        "gnupg"
        "libhdate"
        "links"
        "mosh"
        "msmtp"
        "mutt"
        "myrepos"
        "ncdu"
        "nmap"
        "nss-certs"
        "openssh"
        "parallel"
        "pinentry-tty"
        "qrencode"
        "rsync"
        "screen"
        "sshfs"
        "stow"
        "tig"
        "translate-shell"
        "tree"
        "urlscan"
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
