(define-module (kids_manifest))
(use-modules (guix profiles)
             (gnu packages))

(packages->manifest
 (map (compose list specification->package+output)
      (list
        "font-dejavu"
        "font-terminus"
        "gcompris"
        "gcompris-qt"
        "gnujump"
        "icecat"
        "kodi"
        "ktouch"
        "quadrapassel"
        "supertux"
        "supertuxkart"
        "tuxmath")))
