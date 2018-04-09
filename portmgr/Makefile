THIS_MAKEFILE       := $(lastword $(MAKEFILE_LIST))
THIS_DIR            := $(dir $(THIS_MAKEFILE))
TOP_DIR             := $(THIS_DIR)..

DISTDIR             = $(TOP_DIR)/dist
WORKSRCPATH = $(DISTDIR)/$(DISTNAME)
BUILDDIR    = $(WORKSRCPATH)
DESTDIR     = $(BUILDDIR)/_destroot
GPG_ID              =
VALID_GPG_ID        := $(if $(GPG_ID),,usage)
GIT_TAG             =
# But this is wrong for -beta* and -rc*
MP_VERSION          := $(if $(GIT_TAG),$(shell git show $(GIT_TAG):config/macports_version --),)
GIT_ABBREV          := 7
GIT_ABBREV_COMMIT   := $(if $(MP_VERSION),$(shell git rev-list -1 --abbrev-commit --abbrev=$(GIT_ABBREV) $(GIT_TAG) --),)
VALID_GIT_TAG       := $(if $(MP_VERSION),,usage)
ifeq ($(GIT_TAG),)
DISTNAME    := MacPorts
else
ifeq ($(GIT_TAG),v$(MP_VERSION))
DISTNAME    := MacPorts-$(MP_VERSION)
else
DISTDATE            := $(shell TZ=UTC git log -1 --format=%cd --date=format-local:%Y%m%dT%H%M%SZ $(GIT_TAG) --)
DISTNAME            := MacPorts-$(MP_VERSION)-$(DISTDATE)-$(GIT_ABBREV_COMMIT)
endif
endif
MACOS_VERSION   := $(shell sw_vers -productVersion | cut -d. -f1-2)
OS_PKG          := $(DISTNAME)-for-$(MACOS_VERSION).pkg
DISTFILES   := $(addprefix $(DISTDIR)/$(DISTNAME),.tar.gz .tar.bz2)
CHKFILES    := $(addsuffix .chk.txt,$(DISTFILES))
GPGFILES    := $(addsuffix .asc,$(DISTFILES))

USAGE_MAKE_CMD  = make $(if $(filter-out Makefile,$(THIS_MAKEFILE)),-f $(THIS_MAKEFILE) ,)$(or $(filter-out usage,$(MAKECMDGOALS)),dist)

usage:
ifeq ($(filter sign,$(MAKECMDGOALS)),)
	@echo "Usage: \`$(USAGE_MAKE_CMD) GIT_TAG=v2.4.2' or \`$(USAGE_MAKE_CMD) GIT_TAG=0123456789abcdef'"
else
	@echo "Usage: \`$(USAGE_MAKE_CMD) GPG_ID=<handle>@macports.org GIT_TAG=...'"
endif
	@exit 1

clean:
	rm -rf $(DISTDIR)

$(DISTDIR)/$(DISTNAME).tar: $(VALID_GIT_TAG)
	mkdir -p $(DISTDIR)
	git archive --format=tar --prefix=$(DISTNAME)/ $(GIT_TAG) --output=$@

%.gz: %
	gzip -cn9 < $< > $@

%.bz2: %
	bzip2 -c9 < $< > $@

dist: $(DISTFILES)

$(DISTDIR)/$(DISTNAME).chk.txt: $(VALID_GIT_TAG) $(CHKFILES)
	cat $(sort $^) > $@

%.chk.txt: %
	cd $(dir $<) && for type in md5 sha1 ripemd160 sha256; do \
		openssl dgst -$$type $(notdir $<); \
	done >> $(notdir $@)

chk: $(DISTDIR)/$(DISTNAME).chk.txt

%.asc: $(VALID_GPG_ID) %
	gpg --sign --detach-sig --armor --local-user $(GPG_ID) $<

sign: $(VALID_GIT_TAG) $(GPGFILES)

ospkg: $(OS_PKG)
$(OS_PKG): | ospkgdestroot

ospkgextract: $(WORKSRCPATH)/configure
$(WORKSRCPATH)/configure: | $(DISTDIR)/$(DISTNAME).tar
	tar -C $(DISTDIR) -xf $|

ospkgconfigure: $(BUILDDIR)/Makefile
$(BUILDDIR)/Makefile: | ospkgextract
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && $(abspath $(WORKSRCPATH))/standard_configure.sh

ospkgbuild: $(BUILDDIR)/src/port/port
$(BUILDDIR)/src/port/port: | ospkgconfigure
	$(MAKE) -C $(BUILDDIR) -j$(shell sysctl -n hw.activecpu)

ospkgdestroot: $(DESTDIR)/opt/local/bin/port
$(DESTDIR)/opt/local/bin/port: | ospkgbuild
	@if [ "$(shell id -u)" != "0" ]; then \
		echo "\`make ospkgdestroot' requires administrator privileges"; \
		exit 1; \
	fi
	mkdir -p $(DESTDIR)
	$(MAKE) -C $(BUILDDIR) install DESTDIR=$(abspath $(DESTDIR))
	rm -f $(DESTDIR)/opt/local/etc/macports/*.conf

.PHONY: chk clean dist sign usage
.PHONY: ospkg ospkgbuild ospkgconfigure ospkgdestroot ospkgextract
