(define-module (aarch64-deploy))
(use-modules (pine64)
             (rock64)
             (gnu machine)
             (gnu machine ssh))

(list (machine
        (operating-system %pine64-system)
        (environment managed-host-environment-type)
        (configuration (machine-ssh-configuration
                         (host-name "pine64.unicorn-typhon.ts.net")
                         ;(host-name "192.168.68.51")
                         (system "aarch64-linux")
                         (port 22)
                         (user "efraim")
                         (identity "/home/efraim/.ssh/id_ecdsa")
                         (host-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAhNEOFzg4QMgRzivcJwHQHhbVY0AAHwx9l+65wDMO6X"))))

      (machine
        (operating-system %rock64-system)
        (environment managed-host-environment-type)
        (configuration (machine-ssh-configuration
                         (host-name "rock64.unicorn-typhon.ts.net")
                         ;(host-name "192.168.68.56")
                         (system "aarch64-linux")
                         (port 22)
                         (user "efraim")
                         (identity "/home/efraim/.ssh/id_ecdsa")
                         (host-key "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM46O8629shIIF9WBtr/m7MvFdI5H9jR0PVFGJIcrvdm")))))

;; For /etc/passwd
;; efraim ALL = NOPASSWD: ALL
;; time guix deploy -L ~/workspace/my-guix -L ~/workspace/guix-config ~/workspace/guix-config/aarch64-deploy.scm
