THIS_MAKEFILE       := $(lastword $(MAKEFILE_LIST))
THIS_DIR            := $(dir $(THIS_MAKEFILE))
TOP_DIR             := $(THIS_DIR)..
SPACE               := $(subst ,, )

GPG_ID              :=
VALID_GPG_ID        := $(if $(GPG_ID),,usage)
GIT_TAG             :=
GIT_COMMIT          :=
GIT_TAG_OR_COMMIT   := $(or $(GIT_TAG),$(GIT_COMMIT))
GIT_FULL_COMMIT     := $(if $(GIT_TAG_OR_COMMIT),$(shell git rev-list -1 $(GIT_TAG_OR_COMMIT) --),)
GIT_ABBREV_COMMIT   := $(if $(GIT_FULL_COMMIT),$(shell git rev-list -1 --abbrev-commit --abbrev=7 $(GIT_FULL_COMMIT) --),)
COMMIT_DATE         := $(if $(GIT_FULL_COMMIT),$(shell TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%dT%H%M%SZ $(GIT_FULL_COMMIT) --),)
# But this is wrong for -beta* and -rc*
MP_VERSION          := $(if $(GIT_FULL_COMMIT),$(shell git show $(GIT_FULL_COMMIT):config/macports_version --),)
VALID_GIT_COMMIT    := $(if $(GIT_FULL_COMMIT),,usage)
DISTNAME            := MacPorts$(if $(GIT_ABBREV_COMMIT),-$(MP_VERSION)-$(COMMIT_DATE)-$(GIT_ABBREV_COMMIT),)

MP_PREFIX           := /opt/local

# $(call os_pkg,10.9)
define os_pkg
$(DISTNAME)-for-$(1).pkg
endef

DIST_DIR            := $(TOP_DIR)/dist$(if $(GIT_ABBREV_COMMIT),/$(MP_VERSION)-$(COMMIT_DATE)-$(GIT_ABBREV_COMMIT),)
DMG_DIR             := $(DIST_DIR)/dmg
MACOS_VERSION       := $(shell sw_vers -productVersion | cut -d. -f1-2)
OS_PKG              := $(call os_pkg,$(MACOS_VERSION))
PKG_VERSION         := $(if $(MP_VERSION),0.$(MP_VERSION).0.0.0.0.0,0)
WORKSRCPATH         := $(DIST_DIR)/$(DISTNAME)
BUILD_DIR           := $(WORKSRCPATH)
DEST_ROOT           := $(DIST_DIR)/destroot

PKGBUILD            = /usr/bin/pkgbuild
PRODUCTBUILD        = /usr/bin/productbuild
PACKAGEMAKER_PATH   = $(or $(wildcard /Applications/PackageMaker.app),$(wildcard /Developer/Applications/PackageMaker.app),/Applications/PackageMaker.app)
PACKAGEMAKER        = $(PACKAGEMAKER_PATH)/Contents/MacOS/PackageMaker
PKG_TYPE            = flat
PKG_IDENTIFIER      = org.macports.MacPorts

DISTFILES           := $(addprefix $(DIST_DIR)/$(DISTNAME),.tar.gz .tar.bz2)
CHKFILES            := $(addsuffix .chk.txt,$(DISTFILES))
GPGFILES            := $(addsuffix .asc,$(DISTFILES))

USAGE_MAKE_CMD  = make $(if $(filter-out Makefile,$(THIS_MAKEFILE)),-f $(THIS_MAKEFILE) ,)$(or $(filter-out usage,$(MAKECMDGOALS)),dist)

# Keep these lists sorted in ascending order.
OLD_INSTALLER_MACOS_VERSIONS    := 10.4 10.5
NEW_INSTALLER_MACOS_VERSIONS    := 10.6 10.7 10.8 10.9 10.10 10.11 10.12 10.13

OLD_OS_PKGS                     = $(foreach MACOS_VERSION,$(OLD_INSTALLER_MACOS_VERSIONS),$(DIST_DIR)/$(call os_pkg,$(MACOS_VERSION)))
NEW_OS_PKGS                     = $(foreach MACOS_VERSION,$(NEW_INSTALLER_MACOS_VERSIONS),$(DIST_DIR)/$(call os_pkg,$(MACOS_VERSION)))

OLD_INSTALLER_PKG               := $(DMG_DIR)/$(DISTNAME)-for-$(firstword $(OLD_INSTALLER_MACOS_VERSIONS))-$(lastword $(OLD_INSTALLER_MACOS_VERSIONS)).pkg
OLD_INSTALLER_DMG               := $(DIST_DIR)/$(DISTNAME)-for-$(firstword $(OLD_INSTALLER_MACOS_VERSIONS))-$(lastword $(OLD_INSTALLER_MACOS_VERSIONS)).dmg
NEW_INSTALLER_PKG               := $(DIST_DIR)/$(DISTNAME)-for-$(firstword $(NEW_INSTALLER_MACOS_VERSIONS))+.pkg

# $(call next_version,10.8 10.9) --> returns 10.10
define next_version
$(shell V=$(lastword $(1)) && echo $${V%%.*}.$$(($${V#*.} + 1)))
endef

usage:
	@echo "Usage: \`$(USAGE_MAKE_CMD) $(if $(filter sign,$(MAKECMDGOALS)),GPG_ID=<handle>@macports.org ,)( GIT_TAG=v2.4.3 | GIT_COMMIT=a393413 )'"
	@exit 1

clean:
	rm -rf $(DIST_DIR)

$(DIST_DIR)/$(DISTNAME).tar: $(VALID_GIT_COMMIT)
	mkdir -p $(DIST_DIR)
	git -C $(TOP_DIR) archive --format=tar --prefix=$(DISTNAME)/ $(GIT_FULL_COMMIT) --output=$(abspath $@)

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

$(DIST_DIR)/packageinfo.xml:
	printf '<?xml version="1.0" encoding="utf-8"?>\n' > $@
	printf '<pkg-info relocatable="false" useHFSPlusCompression="true">\n' >> $@
	printf '</pkg-info>\n' >> $@

$(DIST_DIR)/distribution.xml: $(VALID_GIT_COMMIT)
	printf '<?xml version="1.0" encoding="utf-8"?>\n' > $@
	printf '<installer-gui-script minSpecVersion="1">\n' >> $@
	printf '    <allowed-os-versions>\n' >> $@
	printf '        <os-version min="$(firstword $(NEW_INSTALLER_MACOS_VERSIONS))"/>\n' >> $@
	printf '        <os-version before="$(call next_version,$(NEW_INSTALLER_MACOS_VERSIONS))"/>\n' >> $@
	printf '    </allowed-os-versions>\n' >> $@
#	printf '    <background file="background.tiff" mime-type="image/tiff" alignment="bottomleft" scaling="none"/>\n' >> $@
#	printf '    <welcome mime-type="text/html" file="Welcome.html"/>\n' >> $@
	printf '    <choices-outline>\n' >> $@
	printf '$(subst $(SPACE),,$(foreach ,$(NEW_INSTALLER_MACOS_VERSIONS),%s\n))' $(foreach MACOS_VERSION,$(NEW_INSTALLER_MACOS_VERSIONS),'        <line choice="MacPorts-for-$(MACOS_VERSION)"/>') >> $@;
	printf '    </choices-outline>\n' >> $@
	printf '$(subst $(SPACE),,$(foreach ,$(NEW_INSTALLER_MACOS_VERSIONS) $(NEW_INSTALLER_MACOS_VERSIONS) $(NEW_INSTALLER_MACOS_VERSIONS),%s\n))' $(foreach MACOS_VERSION,$(NEW_INSTALLER_MACOS_VERSIONS),'    <choice id="MacPorts-for-$(MACOS_VERSION)" title="MacPorts $(MP_VERSION) for $(MACOS_VERSION)" description="MacPorts $(MP_VERSION) for $(MACOS_VERSION)" visible="true" enabled="my.choice.selected" selected="is_os(&quot;$(MACOS_VERSION)&quot;)">' '        <pkg-ref id="MacPorts-for-$(MACOS_VERSION)">$(call os_pkg,$(MACOS_VERSION))</pkg-ref>' '    </choice>') >> $@;
	printf '    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>\n' >> $@
	printf '    <options customize="always"/>\n' >> $@
	printf '    <script><![CDATA[\n' >> $@
	printf '    function is_os(os) {\n' >> $@
	printf '        return (my.target.systemVersion.ProductVersion + &quot;.&quot;).indexOf(os + &quot;.&quot;) == 0\n' >> $@
	printf '    }\n' >> $@
	printf '    ]]></script>\n' >> $@
	printf '    <title>MacPorts</title>\n' >> $@
	printf '    <volume-check>\n' >> $@
	printf '        <allowed-os-versions>\n' >> $@
	printf '            <os-version min="$(firstword $(NEW_INSTALLER_MACOS_VERSIONS))"/>\n' >> $@
	printf '        </allowed-os-versions>\n' >> $@
	printf '    </volume-check>\n' >> $@
	printf '</installer-gui-script>\n' >> $@

ospkg: $(DIST_DIR)/$(OS_PKG)
$(DIST_DIR)/$(OS_PKG): | ospkgdestroot $(if $(filter flat,$(PKG_TYPE)),$(PKGBUILD) $(DIST_DIR)/packageinfo.xml,$(PACKAGEMAKER))
ifeq ($(PKG_TYPE),flat)
	$(PKGBUILD) --info $(DIST_DIR)/packageinfo.xml --root $(DEST_ROOT)$(MP_PREFIX) --install-location $(MP_PREFIX) --identifier $(PKG_IDENTIFIER) --version $(PKG_VERSION) $@
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

newinstaller: $(NEW_INSTALLER_PKG)
$(NEW_INSTALLER_PKG): $(VALID_GIT_COMMIT) $(PRODUCTBUILD) $(NEW_OS_PKGS) $(DIST_DIR)/distribution.xml
	cd $(DIST_DIR) && $(PRODUCTBUILD) --distribution distribution.xml $(abspath $@)

oldinstaller: $(OLD_INSTALLER_DMG)
$(OLD_INSTALLER_DMG): $(VALID_GIT_COMMIT) $(OLD_INSTALLER_PKG)
	hdiutil create -volname "MacPorts $(MP_VERSION)" -srcfolder $(DMG_DIR) -ov $@

$(OLD_INSTALLER_PKG): $(VALID_GIT_COMMIT) $(OLD_OS_PKGS)
	@echo todo
	@exit 1

.PHONY: chk clean dist sign usage
.PHONY: ospkg ospkgbuild ospkgconfigure ospkgdestroot ospkgextract
.PHONY: newinstaller oldinstaller
