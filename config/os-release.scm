(define-module (config os-release)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (gnu packages package-management)
  #:export (%os-release-file))

(define %os-release-file
  (plain-file "os-release"
              (string-append
                "NAME=\"Guix System\"\n"
                "PRETTY_NAME=\"Guix System\"\n"
                "VERSION=\"" (package-version guix) "\"\n"
                "VERSION_ID=\"" (version-major+minor (package-version guix)) "\"\n"
                "ID=guix\n"
                "HOME_URL=\"https://www.gnu.org/software/guix/\"\n"
                "SUPPORT_URL=\"https://www.gnu.org/software/guix/help/\"\n"
                "BUG_REPORT_URL=\"mailto:bug-guix@gnu.org\"\n")))

