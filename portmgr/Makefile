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

# $(call osbuild,10.9)
define osbuild
$(DISTNAME)-for-$(1)
endef

DIST_DIR            := $(TOP_DIR)/dist$(if $(GIT_ABBREV_COMMIT),/$(MP_VERSION)-$(COMMIT_DATE)-$(GIT_ABBREV_COMMIT),)
DMG_DIR             := $(DIST_DIR)/dmg
MACOS_VERSION       := $(shell sw_vers -productVersion | cut -d. -f1-2)
OSBUILD             := $(call osbuild,$(MACOS_VERSION))
OSBUILD_TBZ2        := $(DIST_DIR)/$(OSBUILD).tbz2
PKG_VERSION         := $(if $(MP_VERSION),0.$(MP_VERSION).0.0.0.0.0,0)
WORKSRCPATH         := $(DIST_DIR)/$(DISTNAME)
BUILD_DIR           := $(WORKSRCPATH)
DEST_ROOT           := $(DIST_DIR)/destroot

PKGBUILD            = /usr/bin/pkgbuild
PRODUCTBUILD        = /usr/bin/productbuild
PACKAGEMAKER_PATH   = $(or $(wildcard /Applications/PackageMaker.app),$(wildcard /Developer/Applications/PackageMaker.app),/Applications/PackageMaker.app)
PACKAGEMAKER        = $(PACKAGEMAKER_PATH)/Contents/MacOS/PackageMaker
PKG_IDENTIFIER      = org.macports.MacPorts
PKG_IDENTIFIER_COMMON   = $(PKG_IDENTIFIER)-common

DISTFILES           := $(addprefix $(DIST_DIR)/$(DISTNAME),.tar.gz .tar.bz2)
CHKFILES            := $(addsuffix .chk.txt,$(DISTFILES))
GPGFILES            := $(addsuffix .asc,$(DISTFILES))

USAGE_MAKE_CMD  = make $(if $(filter-out Makefile,$(THIS_MAKEFILE)),-f $(THIS_MAKEFILE) ,)$(or $(filter-out usage,$(MAKECMDGOALS)),dist)

# Keep these lists sorted in ascending order.
OLD_INSTALLER_MACOS_VERSIONS    := 10.4 10.5
NEW_INSTALLER_MACOS_VERSIONS    := 10.6 10.7 10.8 10.9 10.10 10.11 10.12 10.13

OLD_OSBUILDS                    = $(foreach MACOS_VERSION,$(OLD_INSTALLER_MACOS_VERSIONS),$(DIST_DIR)/$(call osbuild,$(MACOS_VERSION)))
NEW_OSBUILDS                    = $(foreach MACOS_VERSION,$(NEW_INSTALLER_MACOS_VERSIONS),$(DIST_DIR)/$(call osbuild,$(MACOS_VERSION)))

OLD_OSBUILD_TBZ2S               = $(addsuffix .tbz2,$(OLD_OSBUILDS))
NEW_OSBUILD_TBZ2S               = $(addsuffix .tbz2,$(NEW_OSBUILDS))

OLD_INSTALLER_PKG               := $(DMG_DIR)/$(DISTNAME)-for-$(firstword $(OLD_INSTALLER_MACOS_VERSIONS))-$(lastword $(OLD_INSTALLER_MACOS_VERSIONS)).pkg
OLD_INSTALLER_DMG               := $(DIST_DIR)/$(DISTNAME)-for-$(firstword $(OLD_INSTALLER_MACOS_VERSIONS))-$(lastword $(OLD_INSTALLER_MACOS_VERSIONS)).dmg
NEW_INSTALLER_PKG               := $(DIST_DIR)/$(DISTNAME).pkg

# $(call macos_name,10.13) --> returns macOS
MACOS_NAME_CASES := 10.[0-6]) echo Mac OS X;; 10.[7-9]|10.1[0-1]) echo OS X;; *) echo macOS;;
define macos_name
$(shell case "$(1)" in $(MACOS_NAME_CASES) esac)
endef

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
	printf '        <line choice="MacPorts-common"/>\n' >> $@
	printf '$(subst $(SPACE),,$(foreach ,$(NEW_INSTALLER_MACOS_VERSIONS),%s\n))' $(foreach MACOS_VERSION,$(NEW_INSTALLER_MACOS_VERSIONS),'        <line choice="MacPorts-for-$(MACOS_VERSION)"/>') >> $@
	printf '    </choices-outline>\n' >> $@
	printf '    <choice id="MacPorts-common" title="MacPorts $(MP_VERSION) common files" description="MacPorts $(MP_VERSION) common files needed for any version of the Mac operating system." visible="true" enabled="false" selected="true">\n' >> $@
	printf '        <pkg-ref id="MacPorts-common">$(DISTNAME)-common.pkg</pkg-ref>\n' >> $@
	printf '    </choice>\n' >> $@
	printf '$(subst $(SPACE),,$(foreach ,$(NEW_INSTALLER_MACOS_VERSIONS) $(NEW_INSTALLER_MACOS_VERSIONS) $(NEW_INSTALLER_MACOS_VERSIONS),%s\n))' $(foreach MACOS_VERSION,$(NEW_INSTALLER_MACOS_VERSIONS),'    <choice id="MacPorts-for-$(MACOS_VERSION)" title="MacPorts $(MP_VERSION) for $(call macos_name,$(MACOS_VERSION)) $(MACOS_VERSION)" description="MacPorts $(MP_VERSION) files specific to $(call macos_name,$(MACOS_VERSION)) $(MACOS_VERSION)." visible="true" enabled="false" selected="is_os(&quot;$(MACOS_VERSION)&quot;)">' '        <pkg-ref id="MacPorts-for-$(MACOS_VERSION)">$(call osbuild,$(MACOS_VERSION)).pkg</pkg-ref>' '    </choice>') >> $@
	printf '    <domains enable_anywhere="false" enable_currentUserHome="false" enable_localSystem="true"/>\n' >> $@
	printf '    <options customize="always"/>\n' >> $@
	printf '    <script><![CDATA[\n' >> $@
	printf '    function is_os(os) {\n' >> $@
	printf '        return (my.target.systemVersion.ProductVersion + ".").indexOf(os + ".") == 0\n' >> $@
	printf '    }\n' >> $@
	printf '    ]]></script>\n' >> $@
	printf '    <title>MacPorts</title>\n' >> $@
	printf '    <volume-check>\n' >> $@
	printf '        <allowed-os-versions>\n' >> $@
	printf '            <os-version min="$(firstword $(NEW_INSTALLER_MACOS_VERSIONS))"/>\n' >> $@
	printf '        </allowed-os-versions>\n' >> $@
	printf '    </volume-check>\n' >> $@
	printf '</installer-gui-script>\n' >> $@

# Build MacPorts for the current macOS version and pack it in a tbz2.
osbuild: $(OSBUILD_TBZ2)
$(OSBUILD_TBZ2): | $(DIST_DIR)/$(DISTNAME).tar
	@echo "--->  Extracting"
	tar -C $(DIST_DIR) -xf $|
	@echo "--->  Configuring"
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && $(abspath $(WORKSRCPATH))/standard_configure.sh --prefix=$(MP_PREFIX)
	@echo "--->  Building"
	$(MAKE) -C $(BUILD_DIR) -j$(shell sysctl -n hw.activecpu)
	@echo "--->  Staging into destroot"
	mkdir -p $(DEST_ROOT)
# Override DSTGRP and DSTUSR so that we don't have to be root here.
# The permissions will be fixed up when creating the installer pkg.
	$(MAKE) -C $(BUILD_DIR) install DESTDIR=$(abspath $(DEST_ROOT)) DSTGRP=$(shell id -gn) DSTUSR=$(shell id -un)
# Don't overwrite the user's config files.
	rm -f $(DEST_ROOT)$(MP_PREFIX)/etc/macports/*.conf
# TODO: other steps done by MacPorts Portfile
	@echo "--->  Compressing destroot"
	mv $(DEST_ROOT)$(MP_PREFIX) $(DEST_ROOT)/$(OSBUILD)
	tar -C $(DEST_ROOT) -cjf $@ $(OSBUILD)
	@echo "--->  Cleaning"
	rm -rf $(WORKSRCPATH) $(BUILD_DIR) $(DEST_ROOT)

$(DIST_DIR)/$(DISTNAME)-common/sbin/.turd_MacPorts: $(VALID_GIT_COMMIT) $(NEW_OSBUILD_TBZ2S)
	@echo "--->  Extracting OS builds"
	for OSBUILD_TBZ2 in $(OLD_OSBUILD_TBZ2S) $(NEW_OSBUILD_TBZ2S); do \
		tar -C $(DIST_DIR) -xjf $$OSBUILD_TBZ2; \
		rsync -a --include='*/' --exclude='*' $${OSBUILD_TBZ2%.*}/ $(DIST_DIR)/$(DISTNAME)-common/; \
	done
	@echo "--->  Decompressing manpages"
	find $(OLD_OSBUILDS) $(NEW_OSBUILDS) -name '*.gz' -print0 | xargs -0 gzip -d
	@echo "--->  Finding common files"
# todo: don't use fdupes
	pre="$(firstword $(sort $(OLD_OSBUILDS) $(NEW_OSBUILDS)))"; \
	fdupes -1qro name $(OLD_OSBUILDS) $(NEW_OSBUILDS) | while read -r line; do \
		set -- $$line; \
		[ $$# -gt $(words $(OLD_OSBUILDS) $(NEW_OSBUILDS)) ] && echo "Not deduplicating $$# (more than $(words $(OLD_OSBUILDS) $(NEW_OSBUILDS))) copies of $${1:$${#pre}}"; \
		[ $$# -eq $(words $(OLD_OSBUILDS) $(NEW_OSBUILDS)) ] || continue; \
		mv "$$1" "$(DIST_DIR)/$(DISTNAME)-common$${1:$${#pre}}"; \
		shift; \
		rm "$$@"; \
	done
	@echo "--->  Recompressing manpages"
	for DIR in $(OLD_OSBUILDS) $(NEW_OSBUILDS) $(DIST_DIR)/$(DISTNAME)-common; do \
		find $$DIR/share/man -type f -print0 | xargs -0 gzip -9; \
	done
	@echo "--->  Deleting empty directories in OS builds"
	find $(OLD_OSBUILDS) $(NEW_OSBUILDS) -type d -empty -delete
	@echo "--->  Preserving empty directories in common files"
	find $(DIST_DIR)/$(DISTNAME)-common -type d -empty -print0 | xargs -0 -I % touch "%/.turd_MacPorts"

newinstaller: $(NEW_INSTALLER_PKG)
$(NEW_INSTALLER_PKG): $(VALID_GIT_COMMIT) $(PKGBUILD) $(PRODUCTBUILD) $(DIST_DIR)/$(DISTNAME)-common/sbin/.turd_MacPorts $(DIST_DIR)/distribution.xml $(DIST_DIR)/packageinfo.xml
	@echo "--->  Packaging new OS installer"
	$(PKGBUILD) --info $(DIST_DIR)/packageinfo.xml --root $(DIST_DIR)/$(DISTNAME)-common --install-location $(MP_PREFIX) --identifier $(PKG_IDENTIFIER_COMMON) --version $(PKG_VERSION) $(DIST_DIR)/$(DISTNAME)-common.pkg
	for OSBUILD in $(NEW_OSBUILDS); do \
		$(PKGBUILD) --info $(DIST_DIR)/packageinfo.xml --root $$OSBUILD --install-location $(MP_PREFIX) --identifier $(PKG_IDENTIFIER) --version $(PKG_VERSION) $$OSBUILD.pkg; \
	done
	cd $(DIST_DIR) && $(PRODUCTBUILD) --distribution distribution.xml $(abspath $(NEW_INSTALLER_PKG))

oldinstaller: $(OLD_INSTALLER_DMG)
$(OLD_INSTALLER_DMG): $(VALID_GIT_COMMIT) $(OLD_INSTALLER_PKG)
	@echo "--->  Creating old OS installer disk image"
	hdiutil create -volname "MacPorts $(MP_VERSION)" -srcfolder $(DMG_DIR) -ov $@
	@echo todo
	@exit 1

$(OLD_INSTALLER_PKG): $(VALID_GIT_COMMIT) $(PKGBUILD) $(DIST_DIR)/$(DISTNAME)-common/sbin/.turd_MacPorts
	@echo "--->  Packaging old OS installer"
	@echo todo
	@exit 1

.PHONY: chk clean dist sign usage
.PHONY: newinstaller oldinstaller osbuild
