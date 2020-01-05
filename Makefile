SOURCES = \
		  config/guix-daemon.scm \
		  config/os-release.scm \
		  config/xorg-modules.scm \
		  Extras/kernel.scm \
		  E2140_config.scm \
		  E5400_config.scm \
		  macbook41_config.scm \
		  vm_config.scm \
		  firefly_guix_manifest.scm \
		  GuixSD_GUI_manifest.scm

GOBJECTS = $(SOURCES:%.scm=%.go)
%.go: %.scm
	GUILE_LOAD_PATH=.:$(GUILE_LOAD_PATH); \
	GUILE_LOAD_COMPILED_PATH=.:$(GUILE_LOAD_COMPILED_PATH); \
	GUILE_AUTO_COMPILE=0; \
	guild compile -W unbound-variable -o "$@" "$<"

all: $(GOBJECTS)
	echo "done"

clean: $(SOURCES)
	rm -r $(GOBJECTS)
