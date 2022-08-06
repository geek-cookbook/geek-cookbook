#!/bin/bash
set -e
# docker build --build-arg FROM_SOURCE=ghcr.io/geek-cookbook/mkdocs-material-insiders . -t funkypenguin/mkdocs-material --platform amd64

# Prepare slimmed-down versions for PDFing (replace gsed with sed for linux)
cp -rf manuscript docs_to_pdf
find docs_to_pdf -type f -exec gsed -i -e 's/recipe-footer.md/common-links.md/g' {} \;

# Build PDF from slimmed recipes
docker run --rm --name mkdocs-material-build-pdf -e ENABLE_PDF_EXPORT=1\
 -v ${PWD}/docs_to_pdf:/docs\
 -v ${PWD}/mkdocs-pdf-print.yml:/mkdocs-pdf-print.yml\
 funkypenguin/mkdocs-material build -f mkdocs-pdf-print.yml
