.PHONY: all check munge full sans lgc ttf full-ttf sans-ttf lgc-ttf status dist src-dist full-dist sans-dist lgc-dist norm check-harder pre-patch clean

# Release version
VERSION = 2.24
# Snapshot version
SNAPSHOT =
# Initial source directory, assumed read-only
SRCDIR  = src
# Directory where temporary files live
TMPDIR  = tmp
# Directory where final files are created
BUILDDIR  = build
# Directory where final archives are created
DISTDIR = dist

# Release layout
FONTCONFDIR = fontconfig
DOCDIR = .
SCRIPTSDIR = scripts
TTFDIR = ttf
RESOURCEDIR = resources

ifeq "$(SNAPSHOT)" ""
ARCHIVEVER = $(VERSION)
else
ARCHIVEVER = $(VERSION)-$(SNAPSHOT)
endif

SRCARCHIVE  = dejavu-fonts-$(ARCHIVEVER)
FULLARCHIVE = dejavu-fonts-ttf-$(ARCHIVEVER)
SANSARCHIVE = dejavu-sans-ttf-$(ARCHIVEVER)
LGCARCHIVE  = dejavu-lgc-fonts-ttf-$(ARCHIVEVER)

ARCHIVEEXT = .zip .tar.bz2
SUMEXT     = .zip.md5 .tar.bz2.md5 .tar.bz2.sha512

OLDSTATUS   = $(DOCDIR)/status.txt
BLOCKS      = $(RESOURCEDIR)/Blocks.txt
UNICODEDATA = $(RESOURCEDIR)/UnicodeData.txt
FC-LANG     = $(RESOURCEDIR)/fc-lang

GENERATE    = $(SCRIPTSDIR)/generate.pe
TTPOSTPROC  = $(SCRIPTSDIR)/ttpostproc.pl
LGC         = $(SCRIPTSDIR)/lgc.pe
UNICOVER    = $(SCRIPTSDIR)/unicover.pl
LANGCOVER   = $(SCRIPTSDIR)/langcover.pl
STATUS	    = $(SCRIPTSDIR)/status.pl
PROBLEMS    = $(SCRIPTSDIR)/problems.pl
NORMALIZE   = $(SCRIPTSDIR)/sfdnormalize.pl
NARROW      = $(SCRIPTSDIR)/narrow.pe

SRC      := $(wildcard $(SRCDIR)/*.sfd)
SFDFILES := $(patsubst $(SRCDIR)/%, %, $(SRC))
FULLSFD  := $(patsubst $(SRCDIR)/%.sfd, $(TMPDIR)/%.sfd, $(SRC))
NORMSFD  := $(patsubst %, %.norm, $(FULLSFD))
LGCSFD   := $(patsubst $(SRCDIR)/DejaVu%.sfd, $(TMPDIR)/DejaVuLGC%.sfd, $(SRC))
FULLTTF  := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(FULLSFD))
LGCTTF   := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(LGCSFD))

FONTCONF     := $(wildcard $(FONTCONFDIR)/*.conf)
FONTCONFLGC  := $(wildcard $(FONTCONFDIR)/*lgc*.conf)
FONTCONFFULL := $(filter-out $(FONTCONFLGC), $(FONTCONF))

STATICDOC := $(addprefix $(DOCDIR)/, AUTHORS BUGS LICENSE NEWS README)
GENDOCFULL = unicover.txt langcover.txt status.txt
GENDOCSANS = unicover-sans.txt langcover-sans.txt
GENDOCLGC  = unicover-lgc.txt langcover-lgc.txt

all : full sans lgc

$(TMPDIR)/%.sfd: $(SRCDIR)/%.sfd
	@echo "[1] $< => $@"
	install -d $(dir $@)
	sed "s@\(Version:\? \)\(0\.[0-9]\+\.[0-9]\+\|[1-9][0-9]*\.[0-9]\+\)@\1$(VERSION)@" $< > $@
	touch -r $< $@

$(TMPDIR)/DejaVuLGC%.sfd: $(TMPDIR)/DejaVu%.sfd
	@echo "[2] $< => $@"
	sed -e 's,FontName: DejaVu,FontName: DejaVuLGC,'\
	    -e 's,FullName: DejaVu,FullName: DejaVu LGC,'\
	    -e 's,FamilyName: DejaVu,FamilyName: DejaVu LGC,'\
            -e 's,"DejaVu \(\(Sans\|Serif\)*\( Condensed\| Mono\)*\( Bold\)*\( Oblique\|Italic\)*\)","DejaVu LGC \1",g' < $< > $@
	@echo "Stripping unwanted glyphs from $@"
	$(LGC) $@
	touch -r $< $@

$(BUILDDIR)/%.ttf: $(TMPDIR)/%.sfd
	@echo "[3] $< => $@"
	install -d $(dir $@)
	$(GENERATE) $<
	mv $<.ttf $@
	$(TTPOSTPROC) $@
	$(RM) $@~
	touch -r $< $@

$(BUILDDIR)/status.txt: $(FULLSFD)
	@echo "[4] => $@"
	install -d $(dir $@)
	$(STATUS) $(VERSION) $(OLDSTATUS) $(FULLSFD) > $@

$(BUILDDIR)/unicover.txt: $(patsubst %, $(TMPDIR)/%.sfd, DejaVuSans DejaVuSerif DejaVuSansMono)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/DejaVuSans.sfd "Sans" \
	            $(TMPDIR)/DejaVuSerif.sfd "Serif" \
	            $(TMPDIR)/DejaVuSansMono.sfd "Sans Mono" > $@

$(BUILDDIR)/unicover-sans.txt: $(TMPDIR)/DejaVuSans.sfd
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/DejaVuSans.sfd "Sans" > $@

$(BUILDDIR)/unicover-lgc.txt: $(patsubst %, $(TMPDIR)/%.sfd, DejaVuLGCSans DejaVuLGCSerif DejaVuLGCSansMono)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/DejaVuLGCSans.sfd "Sans" \
	            $(TMPDIR)/DejaVuLGCSerif.sfd "Serif" \
	            $(TMPDIR)/DejaVuLGCSansMono.sfd "Sans Mono" > $@

$(BUILDDIR)/langcover.txt: $(patsubst %, $(TMPDIR)/%.sfd, DejaVuSans DejaVuSerif DejaVuSansMono)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/DejaVuSans.sfd "Sans" \
	             $(TMPDIR)/DejaVuSerif.sfd "Serif" \
	             $(TMPDIR)/DejaVuSansMono.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/langcover-sans.txt: $(TMPDIR)/DejaVuSans.sfd
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/DejaVuSans.sfd "Sans" > $@
endif

$(BUILDDIR)/langcover-lgc.txt: $(patsubst %, $(TMPDIR)/%.sfd, DejaVuLGCSans DejaVuLGCSerif DejaVuLGCSansMono)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/DejaVuLGCSans.sfd "Sans" \
	             $(TMPDIR)/DejaVuLGCSerif.sfd "Serif" \
	             $(TMPDIR)/DejaVuLGCSansMono.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/Makefile: Makefile
	@echo "[7] => $@"
	install -d $(dir $@)
	sed -e "s+^VERSION\([[:space:]]*\)=\(.*\)+VERSION = $(VERSION)+g"\
	    -e "s+^SNAPSHOT\([[:space:]]*\)=\(.*\)+SNAPSHOT = $(SNAPSHOT)+g" < $< > $@
	touch -r $< $@

$(TMPDIR)/$(SRCARCHIVE): $(addprefix $(BUILDDIR)/, $(GENDOCFULL) Makefile) $(FULLSFD)
	@echo "[8] => $@"
	install -d -m 0755 $@/{$(SCRIPTSDIR),$(SRCDIR),$(FONTCONFDIR),$(DOCDIR)}
	install -p -m 0644 $(BUILDDIR)/Makefile $@
	install -p -m 0755 $(GENERATE) $(TTPOSTPROC) $(LGC) $(NORMALIZE) \
	                   $(UNICOVER) $(LANGCOVER) $(STATUS) $(PROBLEMS) \
	                   $@/$(SCRIPTSDIR)
	install -p -m 0644 $(FULLSFD) $@/$(SRCDIR)
	install -p -m 0644 $(FONTCONF) $@/$(FONTCONFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(FULLARCHIVE): full
	@echo "[8] => $@"
	install -d -m 0755 $@/{$(TTFDIR),$(FONTCONFDIR),$(DOCDIR)}
	install -p -m 0644 $(FULLTTF) $@/$(TTFDIR)
	install -p -m 0644 $(FONTCONFFULL) $@/$(FONTCONFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(SANSARCHIVE): sans
	@echo "[8] => $@"
	install -d -m 0755 $@/{$(TTFDIR),$(DOCDIR)}
	install -p -m 0644 $(BUILDDIR)/DejaVuSans.ttf $@/$(TTFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCSANS)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(LGCARCHIVE): lgc
	@echo "[8] => $@"
	install -d -m 0755 $@/{$(TTFDIR),$(FONTCONFDIR),$(DOCDIR)}
	install -p -m 0644 $(LGCTTF) $@/$(TTFDIR)
	install -p -m 0644 $(FONTCONFLGC) $@/$(FONTCONFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCLGC)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(DISTDIR)/%.zip: $(TMPDIR)/%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); zip -rv $(abspath $@) $(notdir $<))

$(DISTDIR)/%.tar.bz2: $(TMPDIR)/%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); tar cjvf $(abspath $@) $(notdir $<))

%.md5: %
	@echo "[10] => $@"
	(cd $(dir $<); md5sum -b $(notdir $<) > $(abspath $@))

%.sha512: %
	@echo "[10] => $@"
	(cd $(dir $<); sha512sum -b $(notdir $<) > $(abspath $@))

%.sfd.norm: %.sfd
	@echo "[11] $< => $@"
	$(NORMALIZE) $<
	touch -r $< $@

check : $(NORMSFD)
	for sfd in $^ ; do \
	echo "[12] Checking $$sfd" ;\
	$(PROBLEMS)  $$sfd ;\
	done

munge: $(NORMSFD)
	for sfd in $(SFDFILES) ; do \
	echo "[13] $(TMPDIR)/$$sfd.norm => $(SRCDIR)/$$sfd" ;\
	cp $(TMPDIR)/$$sfd.norm $(SRCDIR)/$$sfd ;\
	done

full : $(FULLTTF) $(addprefix $(BUILDDIR)/, $(GENDOCFULL))

sans : $(addprefix $(BUILDDIR)/, DejaVuSans.ttf $(GENDOCSANS))

lgc : $(LGCTTF) $(addprefix $(BUILDDIR)/, $(GENDOCLGC))

ttf : full-ttf sans-ttf lgc-ttf

full-ttf : $(FULLTTF)

sans-ttf: $(BUILDDIR)/DejaVuSans.ttf

lgc-ttf : $(LGCTTF)

status : $(addprefix $(BUILDDIR)/, $(GENDOCFULL))

dist : src-dist full-dist sans-dist lgc-dist

src-dist :  $(addprefix $(DISTDIR)/$(SRCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

full-dist : $(addprefix $(DISTDIR)/$(FULLARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

sans-dist : $(addprefix $(DISTDIR)/$(SANSARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

lgc-dist :  $(addprefix $(DISTDIR)/$(LGCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

norm : $(NORMSFD)

check-harder : clean check

pre-patch : munge clean

clean :
	$(RM) -r $(TMPDIR) $(BUILDDIR) $(DISTDIR)

condensed: $(NORMSFD)
	$(NARROW) 90 $(TMPDIR)/DejaVuSans.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSans-Bold.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSans-Oblique.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSans-BoldOblique.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSerif.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSerif-Bold.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSerif-Italic.sfd.norm
	$(NARROW) 90 $(TMPDIR)/DejaVuSerif-BoldItalic.sfd.norm
	$(NORMALIZE) $(TMPDIR)/DejaVuSans.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSans-Bold.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSans-Oblique.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSans-BoldOblique.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSerif.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSerif-Bold.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSerif-Italic.sfd.norm.narrow
	$(NORMALIZE) $(TMPDIR)/DejaVuSerif-BoldItalic.sfd.norm.narrow
	cp $(TMPDIR)/DejaVuSans.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSansCondensed.sfd.norm
	cp $(TMPDIR)/DejaVuSans-Bold.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSansCondensed-Bold.sfd.norm
	cp $(TMPDIR)/DejaVuSans-Oblique.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSansCondensed-Oblique.sfd.norm
	cp $(TMPDIR)/DejaVuSans-BoldOblique.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSansCondensed-BoldOblique.sfd.norm
	cp $(TMPDIR)/DejaVuSerif.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSerifCondensed.sfd.norm
	cp $(TMPDIR)/DejaVuSerif-Bold.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSerifCondensed-Bold.sfd.norm
	cp $(TMPDIR)/DejaVuSerif-Italic.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSerifCondensed-Italic.sfd.norm
	cp $(TMPDIR)/DejaVuSerif-BoldItalic.sfd.norm.narrow.norm $(TMPDIR)/DejaVuSerifCondensed-BoldItalic.sfd.norm
