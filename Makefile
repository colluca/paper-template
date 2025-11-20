###########################
# Configuration variables #
###########################

PAPER      ?= paper
SRCDIR      = src
BUILDDIR    = build
FIGDIR      = fig
RESDIR      = res
CLS         =
BST         =
DOCS        =
GLOSSARY    = $(SRCDIR)/glossary.tex
BIBLIO      = $(SRCDIR)/$(PAPER).bib
ARCHIVE     = $(BUILDDIR)/$(PAPER).tar.gz
RELEASENAME =

RESULTS =

PAPER_FIGS           = $(patsubst %.svg,%.pdf,$(wildcard $(FIGDIR)/*.svg))
PAPER_PREREQUISITES  = $(PAPER_FIGS) $(CLS) $(BST) $(RESULTS) $(GLOSSARY) $(BIBLIO)
PAPER_PREREQUISITES += $(SRCDIR)/util.tex

# Diff configuration
REV1 ?= HEAD^
REV2 ?= HEAD

# Required by minted package
PDFLATEX_FLAGS = -shell-escape

######################
# Internal variables #
######################

PAPER_PDF       = $(BUILDDIR)/$(PAPER).pdf
BLIND_PAPER_PDF = $(BUILDDIR)/$(PAPER)-blind.pdf
PAPER_DIFF_PDF  = $(BUILDDIR)/$(PAPER).diff.pdf

DOC_PDFS = $(addprefix $(BUILDDIR)/,$(addsuffix .pdf,$(DOCS)))

DIFF     = $(PAPER)-diff$(REV1)-$(REV2)
DIFF_PDF = $(BUILDDIR)/$(DIFF).pdf

BIBTEX_VARS   = BIBINPUTS="$(TEMPLATE_DIR):$(SRCDIR):$(BUILDDIR):" BSTINPUTS="$(dir $(BST)):"
PDFLATEX_VARS = TEXINPUTS="$(TEMPLATE_DIR):$(SRCDIR):$(BUILDDIR):$(RESDIR):"

BIBTEX   = $(BIBTEX_VARS) bibtex
PDFLATEX = $(PDFLATEX_VARS) pdflatex

TAG = $(shell git describe --exact-match --tags 2>/dev/null)
ifneq ($(strip $(TAG)),)
RELEASE = $(BUILDDIR)/$(RELEASENAME)-$(TAG).pdf
BLIND_RELEASE = $(BUILDDIR)/$(RELEASENAME)-$(TAG)-BLIND.pdf
endif

#############
# Functions #
#############

define CLEANUP_LATEX_ARTIFACTS
	rm -f $(1).aux
	rm -f $(1).bbl
	rm -f $(1).blg
	rm -f $(1).log
	rm -f $(1).out
	rm -f $(1).glsdefs
endef

# Rule template for building simple Latex documents (i.e. without bibliography)
define BUILD_LATEX_SIMPLE
$(BUILDDIR)/$(1).pdf: $(SRCDIR)/$(1).tex | $(BUILDDIR)
	$(PDFLATEX) $(PDFLATEX_FLAGS) -output-directory $(BUILDDIR) $(SRCDIR)/$(1)
	$(call CLEANUP_LATEX_ARTIFACTS,$(BUILDDIR)/$(1))
endef

# Rule template for building complex LaTeX documents (i.e. with bibliography)
define BUILD_LATEX_COMPLEX
$(BUILDDIR)/$(3).pdf: $(1)/$(2).tex $(4) | $(BUILDDIR)
	$(eval VARDEFS := $(foreach var,$(5),\\def\\$(var){} ))
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname $(3) -output-directory $(BUILDDIR) $(VARDEFS) "\input{$(1)/$(2)}"
	$(BIBTEX) $(BUILDDIR)/$(3)
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname $(3) -output-directory $(BUILDDIR) $(VARDEFS) "\input{$(1)/$(2)}"
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname $(3) -output-directory $(BUILDDIR) $(VARDEFS) "\input{$(1)/$(2)}"
endef

#########
# Rules #
#########

.PHONY: all fig paper docs diff blind results arxiv release blind-release clean clean-fig clean-paper

all: results paper docs

fig: $(PAPER_FIGS)

paper: $(PAPER_PDF)

docs: $(DOC_PDFS)

diff: $(DIFF_PDF)

blind: $(BLIND_PAPER_PDF)

results: $(RESULTS)

arxiv: $(ARCHIVE)

release: $(RELEASE)

blind-release: $(BLIND_RELEASE)

$(RESDIR):
	mkdir -p $@

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/$(DIFF).tex: $(SRCDIR)/$(PAPER).tex
	latexdiff-vc -r $(REV1) -r $(REV2) $<
	rm -f $(SRCDIR)/*oldtmp*.tex $(SRCDIR)/*newtmp*.tex
	mv $(SRCDIR)/$(DIFF).tex $(BUILDDIR)

# Generate rule for paper
$(eval $(call BUILD_LATEX_COMPLEX,$(SRCDIR),$(PAPER),$(PAPER),$(PAPER_PREREQUISITES)))

# Generate rule for diff
$(eval $(call BUILD_LATEX_COMPLEX,$(BUILDDIR),$(DIFF),$(DIFF),$(PAPER_PREREQUISITES)))

# Generate rule for blind paper
$(eval $(call BUILD_LATEX_COMPLEX,$(SRCDIR),$(PAPER),$(PAPER)-blind,$(PAPER_PREREQUISITES)))

# Generate rules for all docs
$(foreach doc,$(DOCS),$(eval $(call BUILD_LATEX_SIMPLE,$(doc))))

# Convert vector graphics from SVG to PDF
%.pdf: %.svg
	inkscape $< --export-pdf=$@

$(ARCHIVE): $(SRCDIR) $(RESDIR) $(PAPER_FIGS) $(BUILDDIR)/$(PAPER).bbl
	tar --exclude='**/.gitignore' -czf $@ $(RESDIR) $(PAPER_FIGS) \
		-C $(abspath $(SRCDIR)) $(shell ls $(SRCDIR)) \
		-C $(abspath $(BUILDDIR)) $(PAPER).bbl

$(RELEASE): $(PAPER_PDF)
	cp $(PAPER_PDF) $@

$(BLIND_RELEASE): $(BLIND_PAPER_PDF)
	cp $(BLIND_PAPER_PDF) $@

clean-paper:
	rm -rf $(BUILDDIR)
	$(call CLEANUP_LATEX_ARTIFACTS,*)

clean-fig:
	rm -f $(PAPER_FIGS)

clean: clean-fig clean-paper
	rm -rf $(RESULTS)

###########
# Results #
###########
