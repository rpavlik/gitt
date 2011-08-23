# Those PNG images that have to be exported before we can build the PDF
REQUIRED_PNG_FOR_PDF:=images/f-w5-d1.png images/f-w5-d8.png

# Location of website files
SITE_DIR=site

# Location of website images
SITE_IMAGES_DIR=$(SITE_DIR)/images

SITE_CHAP_IMAGES_DIR=$(SITE_IMAGES_DIR)/chaps

SITE_STYLE_DIR=$(SITE_DIR)/style

# Files created by copying from the html folder to the site folder
HTML_COPIES:=$(SITE_DIR)/stylesheet.css \
	$(SITE_DIR)/index.html

# Lists of all input chapter/afterhours tex files
AFTERHOURS := $(wildcard afterhours*.tex)
CHAPTERS := $(wildcard chap*.tex)
TEX_SOURCES := gitt.cls $(wildcard *.tex)

# Lists of HTML files generated from those tex files
# NOTE - these definitions are incomplete since some produce more than one HTML file,
# but they'll get the job done to set up dependencies properly
AFTERHOURS_HTML := $(AFTERHOURS:%.tex=site/%-1.html)
CHAPTERS_HTML := $(CHAPTERS:%.tex=site/%-1.html)

# Dependencies of all htmlbuild calls except alltex (which generates nav.html)
SIMPLE_GENERATION_DEPS := scripts/htmlbuild.py html/chap-head.html html/chap-foot.html html/nav.html

# All HTML files we need generated and/or copied
ALL_HTML := $(HTML_COPIES) \
	$(AFTERHOURS_HTML) \
	$(CHAPTERS_HTML) \
	site/intro.html \
	site/setup.html

# List of all SVG images
SVG_SOURCES:=$(wildcard images/source/*.svg)

# List of images we can export from SVG, all required at least for the website
PNG_EXPORTED_FROM_SVG:=$(SVG_SOURCES:images/source/%.svg=images/f-%.png)

# All the PNG files that just need to be copied to the chapter site dir
PNG_SOURCES:=$(filter-out $(PNG_EXPORTED_FROM_SVG), $(wildcard images/*.png))

# All images to copy to the chapter site directory, whether exported or not
ALL_PNG_SOURCES:= $(PNG_SOURCES) $(PNG_EXPORTED_FROM_SVG)

# Where they get copied to
SITE_CHAPTER_PNG_FILES:=$(ALL_PNG_SOURCES:images/%=$(SITE_CHAP_IMAGES_DIR)/%)

# Tools - can be overridden by assignment at command line
XELATEX:=$(shell which xelatex)
MAKEINDEX:=$(shell which makeindex)
INKSCAPE:=$(shell which inkscape)
PYTHON:=$(shell which python)

# List of targets that are not files
.PHONY: all quick clean web print pdf screen quickpdf cleantmp cleanpdf cleanimages html htmlimages cleansite
###
# Symbolic targets, for convenience
###
all: pdf cleantmp
quick: quickpdf cleantmp
clean: cleantmp cleanpdf cleanimages cleansite
web: htmlimages html

# An alias for generated the PDF
screen: pdf

# Generate a print version PDF (for lulu.com)
print: $(REQUIRED_PNG_FOR_PDF)
	$(XELATEX) '\def\mediaformat{print}\input{gitt}'
	$(MAKEINDEX) gitt
	$(XELATEX) '\def\mediaformat{print}\input{gitt}'
	$(XELATEX) '\def\mediaformat{print}\input{gitt}'

# Generate the PDF (on-screen version)
pdf: $(REQUIRED_PNG_FOR_PDF)
	$(XELATEX) '\def\mediaformat{screen}\input{gitt}'
	$(MAKEINDEX) gitt
	$(XELATEX) '\def\mediaformat{screen}\input{gitt}'
	$(XELATEX) '\def\mediaformat{screen}\input{gitt}'


# Quickly update the PDF. Will not update the index or cross-references
quickpdf: $(REQUIRED_PNG_FOR_PDF)
	$(XELATEX) gitt

# Remove the temporary files generated by LaTeX
cleantmp:
	rm -f *.aux *.log *.out *.toc *.idx *.ind *.ilg

# Remove the generated PDF
cleanpdf:
	rm -f gitt.pdf

# Remove the generated website images
cleanimages:
	echo "In $@"
	rm -f $(CHAPTER_PNG_FILES) $(PNG_EXPORTED_FROM_SVG)
	rm -f $(SITE_IMAGES_DIR)/*.png

# Clean up generated site files
cleansite:
	echo "In $@"
	rm -fr $(SITE_DIR)
	rm -f html/nav.html

site: html htmlimages

###
# Workhorse rules
###

# Generate PNG file from SVG file
images/f-%.png: images/source/%.svg
	$(INKSCAPE) -f $< -D -w 400 -e $@ >/dev/null

# Generating navigation from gitt.tex
html/nav.html: scripts/htmlbuild.py gitt.tex
	@touch html/nav.html
	$(PYTHON) scripts/htmlbuild.py alltex

# Generating afterhours html
$(AFTERHOURS_HTML): $(AFTERHOURS) $(SIMPLE_GENERATION_DEPS)
	$(PYTHON) scripts/htmlbuild.py allafterhours

# Generating chapters html
$(CHAPTERS_HTML): $(CHAPTERS) $(SIMPLE_GENERATION_DEPS)
	$(PYTHON) scripts/htmlbuild.py allchaps

# Generating other html files from tex files
site/%.html: scripts/htmlbuild.py %.tex $(SIMPLE_GENERATION_DEPS)
	$(PYTHON) scripts/htmlbuild.py $*

# Convert TeX to HTML
html: $(SITE_IMAGES_DIR) $(ALL_HTML)

# Copy these files from html to the site folder verbatim
$(HTML_COPIES): $(SITE_DIR)/%: html/%
	cp $< $@

# Copy images to the site chapter images directory
$(SITE_CHAP_IMAGES_DIR)/%: images/% $(SITE_CHAP_IMAGES_DIR)
	cp $< $@

# Convert/copy all images
htmlimages: $(SITE_CHAPTER_PNG_FILES)
	@cp html/images/* $(SITE_IMAGES_DIR)/

# Make directories
$(SITE_DIR):
	@mkdir -p $(SITE_DIR)

$(SITE_STYLE_DIR):
	@mkdir -p $(SITE_STYLE_DIR)

$(SITE_IMAGES_DIR):
	@mkdir -p $(SITE_IMAGES_DIR)

$(SITE_CHAP_IMAGES_DIR):
	@mkdir -p $(SITE_CHAP_IMAGES_DIR)
