(define-module (config os-release)
  #:use-module (guix gexp)
  #:export (%os-release-file))

(define %os-release-file
  (plain-file "os-release"
              (string-append
                "NAME=\"Guix System\"\n"
                "PRETTY_NAME=\"Guix System\"\n"
                "VERSION=\"" ((@ (guix packages) package-version)
                              (@ (gnu packages package-management) guix)) "\"\n"
                "VERSION_ID=\"" ((@ (guix utils) version-major+minor+point)
                                 ((@ (guix packages) package-version)
                                  (@ (gnu packages package-management) guix))) "\"\n"
                "ID=guix\n"
                "HOME_URL=\"https://www.gnu.org/software/guix/\"\n"
                "SUPPORT_URL=\"https://www.gnu.org/software/guix/help/\"\n"
                "BUG_REPORT_URL=\"mailto:bug-guix@gnu.org\"\n")))

