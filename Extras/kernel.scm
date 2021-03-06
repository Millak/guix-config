(define-module (Extras kernel)
  #:use-module (gnu packages linux)
  #:use-module (guix gexp)
  #:use-module (guix packages))

(define %macbook41-config-options
  `(("CONFIG_USB_NET_RNDIS_HOST" . m)
    ("CONFIG_USB_NET_CDCETHER" . m)
    ("CONFIG_USB_USBNET" . m)
    ("CONFIG_MII" . m)
    ("CONFIG_RT8XXXU" . m)
    ("CONFIG_CRYPTO_ARC4" . m)
    ("CONFIG_RTL8192CU" . m)
    ;; rtlusb
    ("CONFIG_RTL8192C_COMMON" . m)
    ("CONFIG_RTLWIFI" . m)
    ("CONFIG_USB_ACM" . m)
    ("CONFIG_VLAN_8021Q" . m)
    ("CONFIG_GARP" . m)
    ("CONFIG_MRP" . m)
    ("CONFIG_XT_TARGET_CHECKSUM" . m)
    ("CONFIG_IP_NF_MANGLE" . m)
    ("CONFIG_IP_TABLE_MASQUERADE" . m)
    ("CONFIG_IP_NF_NAT" . m)
    ("CONFIG_NF_NAT_IPV4" . m)
    ("CONFIG_NF_NAT" . m)
    ("CONFIG_NETFILTER_XT_MATCH_CONNTRACK" . m)
    ("CONFIG_NF_CONNTRACK" . m)
    ("CONFIG_NF_DEFRAG_IPV6" . m)
    ("CONFIG_NF_DEFRAG_IPV4" . m)
    ("CONFIG_IP_NF_TARGET_REJECT" . m)
    ("CONFIG_NF_REJECT_IPV4" . m)
    ;; tcpudp
    ("CONFIG_BRIDGE" . m)
    ("CONFIG_STP" . m)
    ("CONFIG_LLC" . m)
    ("CONFIG_BRIDGE_EBT_T_FILTER" . m)
    ("CONFIG_BRIDGE_EBTABLES" . m) ; ?
    ("CONFIG_IP6_NF_FILTER" . m)
    ("CONFIG_IP6_NF_IPTABLES" . m)
    ("CONFIG_IP_NF_FILTER" . m)
    ("CONFIG_NET_DEVLINK" . m)
    ;; one of the two following is corrent
    ("CONFIG_IP_NF_TABLES" . m)
    ("CONFIG_IP_NF_IPTABLES" . m)
    ("CONFIG_NETFILTER_XTABLES" . m)
    ("CONFIG_FB_INTEL" . m)
    ("CONFIG_B43" . m)
    ("CONFIG_BCMA" . m)
    ("CONFIG_MAC80211" . m)
    ("CONFIG_INPUT_JOYDEV" . m)
    ("CONFIG_INPUT_LEDS" . m)
    ("CONFIG_CFG80211" . m)
    ("CONFIG_USB_HCD_SSB" . m)
    ("CONFIG_USB_MOUSE" . m)
    ("CONFIG_ITCO_WDT" . m)
    ("CONFIG_ITCO_VENDOR_SUPPORT" . #t)
    ("CONFIG_USB_KBD" . m)
    ("CONFIG_MOUSE_APPLETOUCH" . m)
    ("CONFIG_SENSORS_APPLESMC" . m)
    ("CONFIG_INPUT_POLLDEV" . m)
    ("CONFIG_SENSORS_CORETEMP" . m)
    ("CONFIG_KVM_INTEL" . m)
    ("CONFIG_KVM" . m)
    ("CONFIG_HAVE_KVM_IRQ_BYPASS" . #t)
    ("CONFIG_HID_APPLEIR" . m)
    ("CONFIG_USB_ISIGHTFW" . m)
    ("CONFIG_PCSPKR_PLATFORM" . #t)
    ("CONFIG_I2C_I801" . m)
    ("CONFIG_SND_HDA_CODEC_REALTEK" . m)
    ("CONFIG_FIREWIRE_OHCI" . m)
    ("CONFIG_LPC_ICH" . m)
    ("CONFIG_CRC_ITU_T" . m)
    ("CONFIG_SKY2" . m)
    ("CONFIG_SSB" . m)
    ("CONFIG_DRM_I915" . m)
    ("CONFIG_SND_HDA_INTEL" . m)
    ("CONFIG_ACPI_SBS" . m)
    ("CONFIG_BATTERY_SBS" . m)
    ("CONFIG_CHARGER_SBS" . m)
    ("CONFIG_MANAGER_SBS" . m)
    ("CONFIG_CEC_CORE" . m)
    ("CONFIG_DRM_KMS_HELPER" . m)
    ("CONFIG_SND_HDA_CORE" . m)
    ("CONFIG_SND_HWDEP" . m)
    ("CONFIG_SND_PCM" . m)
    ("CONFIG_DRM" . m)
    ("CONFIG_ACPI_VIDEO" . m)
    ("CONFIG_SND_TIMER" . m)
    ("CONFIG_I2C_ALGOBIT" . m)
    ("CONFIG_BACKLIGHT_APPLE" . m)
    ("CONFIG_HID_APPLE" . m)
    ("CONFIG_FB_SYS_FOPS" . m)
    ("CONFIG_FB_SYS_COPYAREA" . m)
    ("CONFIG_FB_SYS_FILLRECT" . m)
    ("CONFIG_SND" . m)
    ("CONFIG_FB_SYS_IMAGEBLIT" . m)
    ("CONFIG_SOUND" . m)
    ("CONFIG_BTRFS_FS" . m)
    ("CONFIG_XOR_BLOCKS" . m)
    ("CONFIG_RAID6_PQ" . m)
    ("CONFIG_ZSTD_DECOMPRESS" . m)
    ("CONFIG_ZSTD_COMPRESS" . m)
    ("CONFIG_XXHASH" . m)
    ("CONFIG_LIBCRC32C" . m)
    ("CONFIG_HW_RANDOM_VIRTIO" . m)
    ("CONFIG_VIRTIO_CONSOLE" . #t)
    ("CONFIG_VIRTIO_NET" . #t)
    ("CONFIG_VIRTIO_BLK" . #t)
    ("CONFIG_VIRTIO_BALLOON" . #t)
    ("CONFIG_VIRTIO_PCI" . #t)
    ("CONFIG_VIRTIO" . #t)
    ;; virtio_ring
    ("CONFIG_SCSI_ISCI" . m)
    ("CONFIG_SCSI_SAS_LIBSAS" . m)
    ("CONFIG_SCSI_SAS_ATTRS" . m)
    ("CONFIG_PATA_ATIIXP" . m)
    ("CONFIG_PATA_ACPI" . m)
    ("CONFIG_NLS_ISO8859_1" . m)
    ("CONFIG_CRYPTO_WP512" . m)
    ;; is this not a real flag?
    ("CONFIG_CRYPTO_GENERIC" . #t)
    ("CONFIG_CRYPTO_XTS" . m)
    ("CONFIG_DM_CRYPT" . m)
    ("CONFIG_HID" . m)
    ("CONFIG_USB_HID" . m)
    ("CONFIG_USB_UAS" . m)
    ("CONFIG_USB_STORAGE" . m)
    ("CONFIG_SATA_AHCI" . m)
    ("CONFIG_SATA_AHCI_PLATFORM" . m)

    ("CONFIG_USB_EHCI_HCD" . #t)
    ("CONFIG_USB_UHCI_HCD" . #t)

    ("CONFIG_BT" . m)
    ("CONFIG_BT_HCIBTUSB" . m)
    ("CONFIG_BT_BCM" . m)
    ("CONFIG_BT_RTL" . m)
    ("CONFIG_BT_INTEL" . m)

    ;;filesystems
    ;("CONFIG_EXT4_FS" . #t)
    ;("CONFIG_EXT4_USE_FOR_EXT2" . #t)
    ;("CONFIG_XFS_FS" . m)
    ;("CONFIG_MSDOS_FS" . m)
    ;("CONFIG_VFAT_FS" . #t)
    ;("CONFIG_TMPFS" . #t)
    ;("CONFIG_DEVTMPFS" . #t)
    ;("CONFIG_DEVTMPFS_MOUNT" . #t)
    ;("CONFIG_PROC_FS" . #t)
    ;("CONFIG_MSDOS_PARTITION" . #t)

    ;;efi-support
    ;("CONFIG_EFI_PARTITION" . #t)
    ;("CONFIG_EFIVAR_FS" . #t)
    ;("CONFIG_EFI_MIXED" . #t)

    ;("CONFIG_FW_LOADER" . #t)
    ;("CONFIG_FW_LOADER_USER_HELPER" . #t)

    ;;%emulation
    ;("CONFIG_IA32_EMULATION" . #t)
    ;("CONFIG_X86_X32" . #t)

    ;;default-extra-linux-options
    ;; Modules required for initrd:
    ;("CONFIG_NET_9P" . m)
    ;("CONFIG_NET_9P_VIRTIO" . m)
    ;("CONFIG_VIRTIO_BLK" . m)
    ;("CONFIG_VIRTIO_NET" . m)
    ;("CONFIG_VIRTIO_PCI" . m)
    ;("CONFIG_VIRTIO_BALLOON" . m)
    ;("CONFIG_VIRTIO_MMIO" . m)
    ;("CONFIG_FUSE_FS" . m)
    ;("CONFIG_CIFS" . m)
    ;("CONFIG_9P_FS" . m)

    ;;and some other forgotten ones
    ("CONFIG_CRYPTO_SERPENT" . m)
    ("CONFIG_SCSI_ISCI" . m) ; *86

    ("CONFIG_SMP" . #t)

    ))

(define %filesystems
  `(
    ("CONFIG_EXT3_FS" . #t)
    ("CONFIG_EXT4_FS" . #t)
    ("CONFIG_BTRFS_FS" . m)
    ("CONFIG_XFS_FS" . #t)
    ;("CONFIG_XFS_ONLINE_REPAIR" . #t)
    ;("CONFIG_XFS_ONLINE_SCRUB" . #t)
    ("CONFIG_MSDOS_FS" . #t)
    ("CONFIG_VFAT_FS" . #t)
    ("CONFIG_TMPFS" . #t)
    ("CONFIG_DEVTMPFS" . #t)
    ("CONFIG_DEVTMPFS_MOUNT" . #t)
    ("CONFIG_PROC_FS" . #t)
    ("CONFIG_MSDOS_PARTITION" . #t)
    ;; GPT support
    ("CONFIG_PARTITION_ADVANCED" . #t)
    ))

(define %efi-support
  `(
    ("CONFIG_EFI_PARTITION" . #t)
    ("CONFIG_EFIVAR_FS" . #t)
    ("CONFIG_EFI_MIXED" . #t)
    ("CONFIG_EFI_VARS" . #t)

    ("CONFIG_FW_LOADER" . #t)
    ("CONFIG_FW_LOADER_USER_HELPER" . #t)
    ))

(define %emulation
  `(
    ("CONFIG_IA32_EMULATION" . #t)
    ("CONFIG_X86_X32" . #t)
    ))

(define %extra-required-modules
  `(("CONFIG_SATA_AHCI" . m)
    ("CONFIG_USB_STORAGE" . m)
    ("CONFIG_USB_UAS" . m)
    ("CONFIG_USB_HID" . m)
    ("CONFIG_HID_GENERIC" . m)
    ("CONFIG_HID_APPLE" . m)
    ("CONFIG_CRYPTO_XTS" . m)
    ("CONFIG_CRYPTO_SERPENT" . m)
    ;("CONFIG_CRYPTO_SERPENT_SSE2_X86_64" . m)
    ;("CONFIG_CRYPTO_SERPENT_AVX_X86_64" . m)
    ;("CONFIG_CRYPTO_SERPENT_AVX2_X86_64" . m)
    ("CONFIG_CRYPTO_WP512" . m)
    ("CONFIG_NLS_ISO8859_1" . m)
    ("CONFIG_BTRFS_FS" . m)
    ("CONFIG_PATA_ACPI" . m)
    ("CONFIG_PATA_ATIIXP" . m)
    ;("CONFIG_SCSI_ISCI" . m)
    ("CONFIG_VIRTIO_CONSOLE" . m)))

(define %zram-support
  `(("CONFIG_ZSMALLOC" . m)
    ("CONFIG_CRYPTO_LZO" . m)
    ("CONFIG_ZRAM" . m)
    ("CONFIG_ZRAM_WRITEBACK" . #t)))

(define %cisco-anyconnect-support
  ;; need /dev/net/tun
  `(("CONFIG_TUN" . m)))

(define %macbook41-full-config
  (append %macbook41-config-options
          %filesystems
          %efi-support
          %emulation
          (@@ (gnu packages linux) %default-extra-linux-options)))

;(define-public linux-libre-macbook41
;  ((@@ (gnu packages linux) make-linux-libre) (@@ (gnu packages linux) linux-libre-version)
;                    (@@ (gnu packages linux) linux-libre-source)
;                    '("x86_64-linux")
;                    #:extra-version "macbook41"
;                    ;#:patches (@@ (gnu packages linux) %linux-libre-5.0-patches)
;                    #:extra-options %macbook41-full-config))

;(define-public linux-libre-E2140
;  (let ((base
;          ((@@ (gnu packages linux) make-linux-libre)
;           (@@ (gnu packages linux) linux-libre-version)
;           (@@ (gnu packages linux) linux-libre-source)
;           '("x86_64-linux")
;           #:extra-version "E2140"
;           ;#:patches (@@ (gnu packages linux) %linux-libre-5.0-patches)
;           )))
;    (package
;      (inherit base)
;      (native-inputs
;       `(("kconfig" ,(local-file "E2140.config"))
;         ,@(package-native-inputs base))))))

;(define-public linux-libre-kvm
;  (let ((base
;          ((@@ (gnu packages linux) make-linux-libre)
;           (@@ (gnu packages linux) linux-libre-version)
;           (@@ (gnu packages linux) linux-libre-source)
;           '("x86_64-linux")
;           #:extra-version "kvm"
;           #:defconfig "kvmconfig"
;           #:patches (@@ (gnu packages linux) %linux-libre-5.0-patches))))
;    (package
;      (inherit base)
;      (native-inputs
;       `(("kconfig" ,(local-file "5.x-defconfig.config"))
;         ,@(package-native-inputs base))))))

(define-public linux-libre-arm64-generic-zram
  ((@@ (gnu packages linux) make-linux-libre*)
   linux-libre-version
   linux-libre-pristine-source
   '("aarch64-linux")
   #:defconfig "defconfig"
   #:extra-version "arm64-generic"
   #:extra-options
   (append
     %zram-support
     (@@ (gnu packages linux) %default-extra-linux-options))))

(define-public linux-libre-minimal
  ((@@ (gnu packages linux) make-linux-libre*)
   linux-libre-version
   linux-libre-pristine-source
   '("x86_64-linux")
   #:defconfig "defconfig"
   #:extra-version "minimal"
   #:extra-options
   (append
     %extra-required-modules
     %zram-support
     %cisco-anyconnect-support
     (@@ (gnu packages linux) %default-extra-linux-options))))

(define-public linux-libre-3900XT
  ((@@ (gnu packages linux) make-linux-libre*)
   linux-libre-version
   linux-libre-pristine-source
   '("x86_64-linux")
   #:configuration-file (@@ (gnu packages linux) kernel-config)
   #:extra-version "3900XT"
   #:extra-options
   (append
     %zram-support
     %cisco-anyconnect-support
     (@@ (gnu packages linux) %default-extra-linux-options))))


;; From guixvits
;(define custom-linux-libre-arm64-generic
;  ;; customized of 81ea278e05986f9ccee078bd00d4d7fc309dd19c
;  (eval
;    '((lambda ()
;        (use-modules (ice-9 popen) (ice-9 rdelim)
;                     (gnu packages) (guix packages))
;
;        ;; I want working `nft` on our generic kernel.
;        ;; The default linux-libre even not boots on this RockPro64 for me.
;        (define non-spartan-netfilter-settings
;          (letrec* ((kconfig (car (assoc-ref (package-native-inputs linux-libre)
;                                             "kconfig")))
;                    (pipe (open-pipe* OPEN_READ "grep" "-iE"
;                                      "config_(nf|nft|netfilter)(_.*=|=)[ym]$"
;                                      kconfig))
;                    (iter
;                      (lambda (l)
;                        (let ((input (read-line pipe)))
;                          (if (string? input)
;                            (let* ((pair (string-split input #\=))
;                                   (value (if (string= (cadr pair) "y") #t 'm))
;                                   (pa.ir `(,(car pair) . ,value)))
;                              (iter (append l `(,pa.ir))))
;                            l))))
;                    (result (iter '())))
;            (display
;              (string-append "The following was borrowed from\n"
;                             kconfig ":\n"))
;            (for-each (lambda (pa.ir)
;                        (display "   ") (display pa.ir) (newline)) result)
;            (newline)
;
;            result))
;
;        (make-linux-libre* linux-libre-version
;                           linux-libre-source
;                           '("aarch64-linux")
;                           #:defconfig "defconfig"
;                           #:extra-version "custom-arm64-generic"
;                           #:extra-options
;                           (append
;                             `(;; needed to fix the RTC on rockchip platforms
;                               ("CONFIG_RTC_DRV_RK808" . #t)
;                               ;; we store in /run/current-system/kernel/.config
;                               ("CONFIG_IKCONFIG" . #f)
;                               ;; better than ondemand for power-saving.
;                               ("CONFIG_CPU_FREQ_GOV_CONSERVATIVE" . #t)
;                               ("CONFIG_CPU_FREQ_DEFAULT_GOV_CONSERVATIVE" . #t))
;                             non-spartan-netfilter-settings        ; for nftables
;                             %default-extra-linux-options))))
;    (resolve-module '(gnu packages linux))))
