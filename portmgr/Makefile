THIS_MAKEFILE       := $(lastword $(MAKEFILE_LIST))
THIS_DIR            := $(dir $(THIS_MAKEFILE))
TOP_DIR             := $(THIS_DIR)..

DIST_DIR            := $(TOP_DIR)/dist
GPG_ID              :=
VALID_GPG_ID        := $(if $(GPG_ID),,usage)
GIT_TAG             :=
GIT_COMMIT          := $(if $(GIT_TAG),$(shell git rev-list -1 $(GIT_TAG) --),)
GIT_ABBREV_COMMIT   := $(if $(GIT_COMMIT),$(shell git rev-list -1 --abbrev-commit --abbrev=7 $(GIT_COMMIT) --),)
COMMIT_DATE         := $(if $(GIT_COMMIT),$(shell TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%dT%H%M%SZ $(GIT_COMMIT) --),)
# But this is wrong for -beta* and -rc*
MP_VERSION          := $(if $(GIT_COMMIT),$(shell git show $(GIT_COMMIT):config/macports_version --),)
MP_PREFIX           := /opt/local
VALID_GIT_COMMIT    := $(if $(GIT_COMMIT),,usage)
ifeq ($(GIT_COMMIT),)
DISTNAME            := MacPorts
else
ifeq ($(GIT_TAG),v$(MP_VERSION))
DISTNAME            := MacPorts-$(MP_VERSION)
else
DISTNAME            := MacPorts-$(MP_VERSION)-$(COMMIT_DATE)-$(GIT_ABBREV_COMMIT)
endif
endif
MACOS_VERSION       := $(shell sw_vers -productVersion | cut -d. -f1-2)
OS_PKG              := $(DISTNAME)-for-$(MACOS_VERSION).pkg
PKG_VERSION         := $(if $(MP_VERSION),0.$(MP_VERSION).0.0.0.0.0,0)
WORKSRCPATH         := $(DIST_DIR)/$(DISTNAME)
BUILD_DIR           := $(WORKSRCPATH)
DEST_ROOT           := $(BUILD_DIR)/_destroot

PKGBUILD            = /usr/bin/pkgbuild
PACKAGEMAKER_PATH   = $(or $(wildcard /Applications/PackageMaker.app),$(wildcard /Developer/Applications/PackageMaker.app),/Applications/PackageMaker.app)
PACKAGEMAKER        = $(PACKAGEMAKER_PATH)/Contents/MacOS/PackageMaker
PKG_TYPE            = flat
PKG_IDENTIFIER      = org.macports.MacPorts

DISTFILES           := $(addprefix $(DIST_DIR)/$(DISTNAME),.tar.gz .tar.bz2)
CHKFILES            := $(addsuffix .chk.txt,$(DISTFILES))
GPGFILES            := $(addsuffix .asc,$(DISTFILES))

USAGE_MAKE_CMD  = make $(if $(filter-out Makefile,$(THIS_MAKEFILE)),-f $(THIS_MAKEFILE) ,)$(or $(filter-out usage,$(MAKECMDGOALS)),dist)

usage:
	@echo "Usage: \`$(USAGE_MAKE_CMD) $(if $(filter sign,$(MAKECMDGOALS)),GPG_ID=<handle>@macports.org ,)( GIT_TAG=v2.4.3 | GIT_COMMIT=a393413 )'"
	@exit 1

clean:
	rm -rf $(DIST_DIR)

$(DIST_DIR)/$(DISTNAME).tar: $(VALID_GIT_COMMIT)
	mkdir -p $(DIST_DIR)
	git -C $(TOP_DIR) archive --format=tar --prefix=$(DISTNAME)/ $(GIT_COMMIT) --output=$(abspath $@)

%.gz: %
	gzip -cn9 < $< > $@

%.bz2: %
	bzip2 -c9 < $< > $@

dist: $(DISTFILES)

$(DIST_DIR)/$(DISTNAME).chk.txt: $(VALID_GIT_COMMIT) $(CHKFILES)
	cat $(sort $^) > $@

%.chk.txt: %
	cd $(dir $<) && for type in md5 sha1 ripemd160 sha256; do \
		openssl dgst -$$type $(notdir $<); \
	done >> $(notdir $@)

chk: $(DIST_DIR)/$(DISTNAME).chk.txt

%.asc: $(VALID_GPG_ID) %
	gpg --sign --detach-sig --armor --local-user $(GPG_ID) $<

sign: $(VALID_GIT_COMMIT) $(GPGFILES)

$(DIST_DIR)/PackageInfo:
	echo "<pkg-info relocatable=\"false\" useHFSPlusCompression=\"true\">" > $@
	echo "</pkg-info>" >> $@

ospkg: $(DIST_DIR)/$(OS_PKG)
$(DIST_DIR)/$(OS_PKG): | ospkgdestroot $(if $(filter flat,$(PKG_TYPE)),$(PKGBUILD) $(DIST_DIR)/PackageInfo,$(PACKAGEMAKER))
ifeq ($(PKG_TYPE),flat)
	$(PKGBUILD) --info $(DIST_DIR)/PackageInfo --root $(DEST_ROOT)$(MP_PREFIX) --install-location $(MP_PREFIX) --identifier $(PKG_IDENTIFIER) --version $(PKG_VERSION) $@
#--scripts $(PKG_SCRIPTS)
else
#PackageMaker method
endif

ospkgextract: $(WORKSRCPATH)/configure
$(WORKSRCPATH)/configure: | $(DIST_DIR)/$(DISTNAME).tar
	tar -C $(DIST_DIR) -xf $|

ospkgconfigure: $(BUILD_DIR)/Makefile
$(BUILD_DIR)/Makefile: | ospkgextract
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(abspath $(WORKSRCPATH))/standard_configure.sh --prefix=$(MP_PREFIX)

ospkgbuild: $(BUILD_DIR)/src/port/port
$(BUILD_DIR)/src/port/port: | ospkgconfigure
	$(MAKE) -C $(BUILD_DIR) -j$(shell sysctl -n hw.activecpu)

ospkgdestroot: $(DEST_ROOT)$(MP_PREFIX)/bin/port
$(DEST_ROOT)$(MP_PREFIX)/bin/port: | ospkgbuild
	mkdir -p $(DEST_ROOT)
	$(MAKE) -C $(BUILD_DIR) install DESTDIR=$(abspath $(DEST_ROOT)) DSTGRP=$(shell id -gn) DSTUSR=$(shell id -un)
	rm -f $(DEST_ROOT)$(MP_PREFIX)/etc/macports/*.conf
	find $(DEST_ROOT) -type d -empty -print0 | xargs -0 -I % -n 1 touch "%/.turd_MacPorts"
# TODO: other steps done by MacPorts Portfile

.PHONY: chk clean dist sign usage
.PHONY: ospkg ospkgbuild ospkgconfigure ospkgdestroot ospkgextract
