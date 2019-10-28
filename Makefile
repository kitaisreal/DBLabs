BUILD_FOLDER = build
PDF_FOLDER = pdf
LATEX_BUILD_FILE = pdflatex -output-directory $(BUILD_FOLDER)
PANDOC=pandoc
FILES=Overview Lab1 Lab2 Lab3 Lab4
README_TEX_FILE_NAME = Overview
README_FILE_NAME = Readme.md
.DEFAULT_GOAL = build

build_pdf:
	@for file_name in $(FILES); do \
		$(LATEX_BUILD_FILE) $${file_name}.tex; \
		cp $(BUILD_FOLDER)/$${file_name}.pdf $(PDF_FOLDER)/$${file_name}.pdf; \
	done
		
build_markdown:
	@for file_name in $(FILES); do \
		$(PANDOC) $${file_name}.tex -o $${file_name}.md --to=gfm; \
	done; \
	mv $(README_TEX_FILE_NAME).md $(README_FILE_NAME)

build: build_pdf build_markdown
	echo "Build finish"