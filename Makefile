###########################
# Configuration variables #
###########################

PAPER   ?= paper
SRCDIR   = src
BUILDDIR = build
RESDIR   = res
CLS      =
BST      =
DOCS     =
GLOSSARY = $(SRCDIR)/glossary.tex
BIBLIO   = $(SRCDIR)/$(PAPER).bib

RESULTS        =
RESULTS_SCRIPT =

PAPER_FIGS          = $(patsubst %.svg,%.pdf,$(wildcard fig/*.svg))
PAPER_PREREQUISITES = $(PAPER_FIGS) $(CLS) $(BST) $(RESULTS) $(GLOSSARY) $(BIBLIO)

# Diff configuration
REV1 ?= HEAD^
REV2 ?= HEAD

# Required by minted package
PDFLATEX_FLAGS = -shell-escape

######################
# Internal variables #
######################

PAPER_PDF      = $(BUILDDIR)/$(PAPER).pdf
PAPER_DIFF_PDF = $(BUILDDIR)/$(PAPER).diff.pdf

DOC_PDFS = $(addprefix $(BUILDDIR)/,$(addsuffix .pdf,$(DOCS)))

DIFF     = $(PAPER)-diff$(REV1)-$(REV2)
DIFF_PDF = $(BUILDDIR)/$(DIFF).pdf

BIBTEX_VARS   = BIBINPUTS="$(SRCDIR):$(BUILDDIR):"
PDFLATEX_VARS = TEXINPUTS="$(SRCDIR):$(BUILDDIR):"

BIBTEX   = $(BIBTEX_VARS) bibtex
PDFLATEX = $(PDFLATEX_VARS) pdflatex

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

# Rule template for building complex Latex documents (i.e. with bibliography)
define BUILD_LATEX_COMPLEX
$(BUILDDIR)/$(2).pdf: $(1)/$(2).tex $(3) | $(BUILDDIR)
	$(PDFLATEX) $(PDFLATEX_FLAGS) -output-directory $(BUILDDIR) $(1)/$(2)
	$(BIBTEX) $(BUILDDIR)/$(2)
	$(PDFLATEX) $(PDFLATEX_FLAGS) -output-directory $(BUILDDIR) $(1)/$(2)
	$(PDFLATEX) $(PDFLATEX_FLAGS) -output-directory $(BUILDDIR) $(1)/$(2)
endef

#########
# Rules #
#########

.PHONY: all paper docs diff results clean

all: results paper docs

paper: $(PAPER_PDF)

docs: $(DOC_PDFS)

diff: $(DIFF_PDF)

results: $(RESULTS)

$(RESDIR):
	mkdir -p $@

$(RESULTS): $(RESULTS_SCRIPT) | $(RESDIR)
	$<

$(BUILDDIR):
	mkdir -p $@

$(BUILDDIR)/$(DIFF).tex: $(SRCDIR)/$(PAPER).tex
	latexdiff-vc -r $(REV1) -r $(REV2) $<
	rm -f $(SRCDIR)/*oldtmp*.tex $(SRCDIR)/*newtmp*.tex
	mv $(SRCDIR)/$(DIFF).tex $(BUILDDIR)

# Generate rule for paper
$(eval $(call BUILD_LATEX_COMPLEX,$(SRCDIR),$(PAPER),$(PAPER_PREREQUISITES)))

# Generate rule for diff
$(eval $(call BUILD_LATEX_COMPLEX,$(BUILDDIR),$(DIFF),$(PAPER_PREREQUISITES)))

# Generate rules for all docs
$(foreach doc,$(DOCS),$(eval $(call BUILD_LATEX_SIMPLE,$(doc))))

# Convert vector graphics from SVG to PDF
%.pdf: %.svg
	inkscape $< --export-pdf=$@

clean:
	rm -rf $(BUILDDIR)
	$(call CLEANUP_LATEX_ARTIFACTS,*)
