.PHONY: all full sans lgc ttf full-ttf sans-ttf lgc-ttf dist src-dist full-dist sans-dist lgc-dist check full-check sans-check lgc-check clean

# Release version
VERSION = 2.21
# Snapshot version
SNAPSHOT =
# Initial source directory, assumed read-only
SRCDIR  = ./
# Directory where temporary files live
TMPDIR  = tmp/
# Directory where final files are created
BUILDDIR  = build/
# Directory where final archives are created
DISTDIR = dist/

ifeq "$(SNAPSHOT)" ""
ARCHIVEVER = $(VERSION)
else
ARCHIVEVER = $(VERSION)-$(SNAPSHOT)
endif

SRCARCHIVE  = dejavu-fonts-$(ARCHIVEVER)
FULLARCHIVE = dejavu-fonts-ttf-$(ARCHIVEVER)
SANSARCHIVE = dejavu-sans-ttf-$(ARCHIVEVER)
LGCARCHIVE  = dejavu-lgc-fonts-ttf-$(ARCHIVEVER)


OLDSTATUS   = ./status.txt
BLOCKS      = ./Blocks.txt
UNICODEDATA = ./UnicodeData.txt
FC-LANG     = ./fc-lang

GENERATE    = ./generate.pe
TTPOSTPROC  = ./ttpostproc.pl
LGC         = ./lgc.pe
UNICOVER    = ./unicover.pl
LANGCOVER   = ./langcover.pl
STATUS	    = ./status.pl
PROBLEMS    = ./problems.pl

SRC     := $(wildcard $(SRCDIR)*.sfd)
FULLSFD := $(patsubst $(SRCDIR)%.sfd,       $(TMPDIR)%.sfd,          $(SRC))
LGCSFD  := $(patsubst $(SRCDIR)DejaVu%.sfd, $(TMPDIR)DejaVuLGC%.sfd, $(SRC))
FULLTTF := $(patsubst $(TMPDIR)%.sfd, $(BUILDDIR)%.ttf, $(FULLSFD))
LGCTTF  := $(patsubst $(TMPDIR)%.sfd, $(BUILDDIR)%.ttf, $(LGCSFD))

all : full sans lgc

$(TMPDIR)%.sfd: $(SRCDIR)%.sfd
	@echo "[1] $< => $@"
	install -d $(dir $@)
	sed "s@\(Version:\? \)\(0\.[0-9]\+\.[0-9]\+\|[1-9][0-9]*\.[0-9]\+\)@\1$(VERSION)@" $< > $@
	touch -r $< $@

$(TMPDIR)DejaVuLGC%.sfd: $(TMPDIR)DejaVu%.sfd
	@echo "[2] $< => $@"
	sed -e 's,FontName: DejaVu,FontName: DejaVuLGC,'\
	    -e 's,FullName: DejaVu,FullName: DejaVu LGC,'\
	    -e 's,FamilyName: DejaVu,FamilyName: DejaVu LGC,'\
            -e 's,"DejaVu \(\(Sans\|Serif\)*\( Condensed\| Mono\)*\( Bold\)*\( Oblique\|Italic\)*\)","DejaVu LGC \1",g' < $< > $@
	@echo "Stripping unwanted glyphs from $@"
	$(LGC) $@
	touch -r $< $@

$(BUILDDIR)%.ttf: $(TMPDIR)%.sfd
	@echo "[3] $< => $@"
	install -d $(dir $@)
	$(GENERATE) $<
	mv $<.ttf $@
	$(TTPOSTPROC) $@
	$(RM) $@~
	touch -r $< $@

$(BUILDDIR)status.txt: $(FULLSFD)
	@echo "[4] => $@"
	install -d $(dir $@)
	$(STATUS) $(VERSION) $(OLDSTATUS) $(FULLSFD) > $@

$(BUILDDIR)unicover.txt: $(TMPDIR)DejaVuSans.sfd $(TMPDIR)DejaVuSerif.sfd $(TMPDIR)DejaVuMonoSans.sfd
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)DejaVuSans.sfd "Sans" \
	            $(TMPDIR)DejaVuSerif.sfd "Serif" \
	            $(TMPDIR)DejaVuMonoSans.sfd "Sans Mono" > $@

$(BUILDDIR)unicover-sans.txt: $(TMPDIR)DejaVuSans.sfd
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)DejaVuSans.sfd "Sans" > $@

$(BUILDDIR)unicover-lgc.txt: $(TMPDIR)DejaVuLGCSans.sfd $(TMPDIR)DejaVuLGCSerif.sfd $(TMPDIR)DejaVuLGCMonoSans.sfd
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)DejaVuLGCSans.sfd "Sans" \
	            $(TMPDIR)DejaVuLGCSerif.sfd "Serif" \
	            $(TMPDIR)DejaVuLGCMonoSans.sfd "Sans Mono" > $@

$(BUILDDIR)langcover.txt: $(TMPDIR)DejaVuSans.sfd $(TMPDIR)DejaVuSerif.sfd $(TMPDIR)DejaVuMonoSans.sfd
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)DejaVuSans.sfd "Sans" \
	             $(TMPDIR)DejaVuSerif.sfd "Serif" \
	             $(TMPDIR)DejaVuMonoSans.sfd "Sans Mono" > $@
endif

$(BUILDDIR)langcover-sans.txt: $(TMPDIR)DejaVuSans.sfd
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)DejaVuSans.sfd "Sans" > $@
endif

$(BUILDDIR)langcover-lgc.txt: $(TMPDIR)DejaVuLGCSans.sfd $(TMPDIR)DejaVuLGCSerif.sfd $(TMPDIR)DejaVuLGCMonoSans.sfd
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)DejaVuLGCSans.sfd "Sans" \
	             $(TMPDIR)DejaVuLGCSerif.sfd "Serif" \
	             $(TMPDIR)DejaVuLGCMonoSans.sfd "Sans Mono" > $@
endif

$(BUILDDIR)Makefile: Makefile
	@echo "[7] => $@"
	install -d $(dir $@)
	sed -e "s+^VERSION\([[:space:]]*\)=\(.*\)+VERSION = $(VERSION)+g"\
	    -e "s+^SNAPSHOT\([[:space:]]*\)=\(.*\)+SNAPSHOT = $(SNAPSHOT)+g" < $< > $@
	touch -r $< $@

$(TMPDIR)$(SRCARCHIVE): $(BUILDDIR)unicover.txt $(BUILDDIR)langcover.txt $(BUILDDIR)Makefile
	@echo "[8] => $@"
	install -d -m 0755 $@
	install -p -m 0755 $(GENERATE) $(TTPOSTPROC) $(LGC) \
	                   $(UNICOVER) $(LANGCOVER) $(STATUS) $(PROBLEMS) \
	                   $@
	install -p -m 0644 $(FULLSFD) \
	                   $(BUILDDIR)Makefile \
	                   $(BUILDDIR)unicover.txt \
                           $(BUILDDIR)langcover.txt \
	                   $(BUILDDIR)status.txt \
	                   AUTHORS BUGS LICENSE NEWS README \
	                   $@

$(TMPDIR)$(FULLARCHIVE): full
	@echo "[8] => $@"
	install -d -m 0755 $@/{doc,ttf}
	install -p -m 0644 $(FULLTTF) $@/ttf
	install -p -m 0644 $(BUILDDIR)unicover.txt \
                           $(BUILDDIR)langcover.txt \
	                   $(BUILDDIR)status.txt \
	                   AUTHORS BUGS LICENSE NEWS README \
	                   $@/doc

$(TMPDIR)$(SANSARCHIVE): sans
	@echo "[8] => $@"
	install -d -m 0755 $@/{doc,ttf}
	install -p -m 0644 $(BUILDDIR)DejaVuSans.ttf $@/ttf
	install -p -m 0644 $(BUILDDIR)unicover-sans.txt \
                           $(BUILDDIR)langcover-sans.txt \
	                   AUTHORS BUGS LICENSE NEWS README \
	                   $@/doc

$(TMPDIR)$(LGCARCHIVE): lgc
	@echo "[8] => $@"
	install -d -m 0755 $@/{doc,ttf}
	install -p -m 0644 $(LGCTTF) $@/ttf
	install -p -m 0644 $(BUILDDIR)unicover-lgc.txt \
                           $(BUILDDIR)langcover-lgc.txt \
	                   AUTHORS BUGS LICENSE NEWS README \
	                   $@/doc

$(DISTDIR)%.zip: $(TMPDIR)%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); zip -rv $(abspath $@) $(notdir $<))

$(DISTDIR)%.tar.bz2: $(TMPDIR)%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); tar cjvf $(abspath $@) $(notdir $<))

%.md5: %
	@echo "[10] => $@"
	(cd $(dir $<); md5sum -b $(notdir $<) > $(abspath $@))

%.sha512: %
	@echo "[10] => $@"
	(cd $(dir $<); sha512sum -b $(notdir $<) > $(abspath $@))

full : $(FULLTTF) $(BUILDDIR)unicover.txt $(BUILDDIR)langcover.txt $(BUILDDIR)status.txt

sans : $(BUILDDIR)DejaVuSans.ttf $(BUILDDIR)unicover-sans.txt $(BUILDDIR)langcover-sans.txt

lgc : $(LGCTTF) $(BUILDDIR)unicover-lgc.txt $(BUILDDIR)langcover-lgc.txt

ttf : full-ttf sans-ttf lgc-ttf

full-ttf : $(FULLTTF)

sans-ttf: $(BUILDDIR)DejaVuSans.ttf

lgc-ttf : $(LGCTTF)

dist : src-dist full-dist sans-dist lgc-dist

src-dist : $(DISTDIR)$(SRCARCHIVE).zip \
           $(DISTDIR)$(SRCARCHIVE).zip.md5 \
           $(DISTDIR)$(SRCARCHIVE).zip.sha512 \
           $(DISTDIR)$(SRCARCHIVE).tar.bz2 \
           $(DISTDIR)$(SRCARCHIVE).tar.bz2.md5 \
           $(DISTDIR)$(SRCARCHIVE).tar.bz2.sha512

full-dist : $(DISTDIR)$(FULLARCHIVE).zip \
            $(DISTDIR)$(FULLARCHIVE).zip.md5 \
            $(DISTDIR)$(FULLARCHIVE).zip.sha512 \
            $(DISTDIR)$(FULLARCHIVE).tar.bz2 \
            $(DISTDIR)$(FULLARCHIVE).tar.bz2.md5 \
            $(DISTDIR)$(FULLARCHIVE).tar.bz2.sha512

sans-dist: $(DISTDIR)$(SANSARCHIVE).zip \
           $(DISTDIR)$(SANSARCHIVE).zip.md5 \
           $(DISTDIR)$(SANSARCHIVE).zip.sha512

lgc-dist : $(DISTDIR)$(LGCARCHIVE).zip \
           $(DISTDIR)$(LGCARCHIVE).zip.md5 \
           $(DISTDIR)$(LGCARCHIVE).zip.sha512 \
           $(DISTDIR)$(LGCARCHIVE).tar.bz2 \
           $(DISTDIR)$(LGCARCHIVE).tar.bz2.md5 \
           $(DISTDIR)$(LGCARCHIVE).tar.bz2.sha512

check : full-check

full-check : $(FULLSFD)
	$(PROBLEMS) $<

sans-check : $(TMPDIR)DejaVuSans.sfd
	$(PROBLEMS) $<

lgc-check : $(LGCSFD)
	$(PROBLEMS) $<

clean :
	$(RM) -r $(TMPDIR) $(BUILDDIR) $(DISTDIR)
