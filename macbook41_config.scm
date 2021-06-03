(define-module (macbook41_config))
(use-modules (guix store)
             (guix gexp)
             (gnu)
             (gnu system locale)
             (config filesystems)
             (config guix-daemon)
             (config os-release)
             (config xorg-modules)
             (srfi srfi-1))
(use-service-modules
  dns
  linux
  mcron
  networking
  ssh
  sysctl)
(use-package-modules
  certs
  linux)

(define %my-macbook-touchpad
  "Section \"InputClass\"
      Identifier \"touchpad catchall\"
      Driver \"libinput\"
      MatchIsTouchpad \"on\"
      Option \"ClickMethod\" \"clickfinger\"
      Option \"TappingButtonMap\" \"lrm\"
  EndSection")

(define %iptables-ipv4-rules
  (plain-file "iptables.rules" "*nat
              :PREROUTING ACCEPT
              :INPUT ACCEPT
              :OUTPUT ACCEPT
              :POSTROUTING ACCEPT

              # eno2 is WAN interface, #eno1 is LAN interface
              -A POSTROUTING -o eno2 -j MASQUERADE

              COMMIT

              *filter
              :INPUT ACCEPT
              :FORWARD ACCEPT
              :OUTPUT ACCEPT

              # Service rules

              # basic global accept rules - ICMP, loopback, traceroute, established all accepted
              -A INPUT -s 127.0.0.0/8 -d 127.0.0.0/8 -i lo -j ACCEPT
              -A INPUT -p icmp -j ACCEPT
              -A INPUT -m state --state ESTABLISHED -j ACCEPT

              # enable traceroute rejections to get sent out
              -A INPUT -p udp -m udp --dport 33434:33523 -j REJECT --reject-with icmp-port-unreachable

              # DNS - accept from LAN
              -A INPUT -i eno1 -p tcp --dport 53 -j ACCEPT
              -A INPUT -i eno1 -p udp --dport 53 -j ACCEPT

              # SSH - accept from LAN
              -A INPUT -i eno1 -p tcp --dport 22 -j ACCEPT

              # DHCP client requests - accept from LAN
              -A INPUT -i eno1 -p udp --dport 67:68 -j ACCEPT

              # drop all other inbound traffic
              -A INPUT -j DROP

              # Forwarding rules

              # forward packets along established/related connections
              -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

              # forward from LAN (eno1) to WAN (eno2)
              -A FORWARD -i eno1 -o eno2 -j ACCEPT

              # drop all other forwarded traffic
              -A FORWARD -j DROP

              COMMIT
              "))

(define %iptables-ipv6-rules
  (plain-file "iptables6.rules" "*nat
              :PREROUTING ACCEPT [0:0]
              :INPUT ACCEPT [0:0]
              :OUTPUT ACCEPT [0:0]
              :POSTROUTING ACCEPT [0:0]

              # eno2 is WAN interface, #eno1 is LAN interface
              -A POSTROUTING -o eno2 -j MASQUERADE

              COMMIT

              *filter
              :INPUT ACCEPT [0:0]
              :FORWARD ACCEPT [0:0]
              :OUTPUT ACCEPT [0:0]

              # Service rules

              # basic global accept rules - ICMP, loopback, traceroute, established all accepted
              -A INPUT -s 127.0.0.0/8 -d 127.0.0.0/8 -i lo -j ACCEPT
              -A INPUT -p icmp -j ACCEPT
              -A INPUT -m state --state ESTABLISHED -j ACCEPT

              # enable traceroute rejections to get sent out
              -A INPUT -p udp -m udp --dport 33434:33523 -j REJECT --reject-with icmp-port-unreachable

              # DNS - accept from LAN
              -A INPUT -i eno1 -p tcp --dport 53 -j ACCEPT
              -A INPUT -i eno1 -p udp --dport 53 -j ACCEPT

              # SSH - accept from LAN
              -A INPUT -i eno1 -p tcp --dport 22 -j ACCEPT

              # DHCP client requests - accept from LAN
              -A INPUT -i eno1 -p udp --dport 67:68 -j ACCEPT

              # drop all other inbound traffic
              -A INPUT -j DROP

              # Forwarding rules

              # forward packets along established/related connections
              -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

              # forward from LAN (eno1) to WAN (eno2)
              -A FORWARD -i eno1 -o eno2 -j ACCEPT

              # drop all other forwarded traffic
              -A FORWARD -j DROP

              COMMIT
              "))
(operating-system
  (host-name "macbook41")
  (timezone "Asia/Jerusalem")
  (locale "en_US.UTF-8")
  (locale-definitions
    (list (locale-definition (source "en_US")
                             (name "en_US.UTF-8"))
          (locale-definition (source "he_IL")
                             (name "he_IL.UTF-8"))))

  ;; Assuming /dev/sdX is the target hard disk, and "my-root"
  ;; is the label of the target root file system.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (target "/boot/efi")))

  (file-systems (cons* (file-system
                         (device (file-system-label "my-root"))
                         (mount-point "/")
                         (type "btrfs")
                         (options "autodefrag,compress=zstd,discard,ssd_spread"))
                       (file-system
                         (device (uuid "F010-1913" 'fat))
                         (mount-point "/boot/efi")
                         (type "vfat"))
                       %guix-temproots
                       %base-file-systems))

  (users (cons (user-account
                (name "efraim")
                (comment "Efraim")
                (group "users")
                (supplementary-groups '("wheel" "netdev" "kvm"))
                (home-directory "/home/efraim"))
               %base-user-accounts))

  (packages (cons* nss-certs         ;for HTTPS access
                   btrfs-progs compsize
                   %base-packages))

  (services
    (cons* (simple-service 'os-release etc-service-type
                           `(("os-release" ,%os-release-file)))

           (service openssh-service-type
                    (openssh-configuration
                      (password-authentication? #f)
                      (authorized-keys
                        `(("efraim" ,(local-file "Extras/efraim.pub"))))))

           (service tor-service-type)
           (tor-hidden-service "ssh"
                               '((22 "127.0.0.1:22")))

           (service zram-device-service-type
                    (zram-device-configuration
                      (size (* 2 (expt 2 30)))
                      (compression-algorithm 'zstd)
                      (priority 100)))

           (service mcron-service-type
                    (mcron-configuration
                      (jobs (%btrfs-maintenance-jobs "/"))))

           (service openntpd-service-type
                    (openntpd-configuration
                      ;; expand to rest of LAN
                      (listen-on '("127.0.0.1" "192.168.1.0/24" "::1"))
                      (constraints-from '("https://www.google.com/"))))

           ;(service wpa-supplicant-service-type)
           ;(service connman-service-type)
           (service dnsmasq-service-type)

           (static-networking-service
             ;; interior Ethernet port, LAN side
             "eno1"
             "192.168.1.1"
             #:netmask "255.255.255.0"
             ;#:gateway
             ;#:name-servers '("208.67.222.222" "208.67.220.220") ; opendns
             ;#:name-servers '("8.8.8.8" "8.8.4.4") ; google
             )

           (service iptables-service-type
                    (iptables-configuration
                      ;(ipv4-rules %iptables-ipv4-rules)
                      ;(ipv6-rules %iptables-ipv6-rules)
                      ))

           ;(service polkit-wheel-service)
           ;(service usb-modeswitch-service-type)
           (modify-services
             %base-services
             (sysctl-service-type
               config =>
               (sysctl-configuration
                 (settings (append '(("net.ipv4.ip_forward" . "1")
                                     ("net.ipv6.conf.all.forwarding" . "1"))
                                   %default-sysctl-settings))))

             (guix-service-type
               config =>
               (guix-configuration
                 (inherit config)
                 (discover? #t)
                 (substitute-urls %substitute-urls)
                 (authorized-keys %authorized-keys)
                 (extra-options
                   (cons* "--cores=1" ; we're on a laptop
                          %extra-options)))))))

  ;; Allow resolution of '.local' host names with mDNS.
  (name-service-switch %mdns-host-lookup-nss))
