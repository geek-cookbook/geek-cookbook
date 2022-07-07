#!/bin/bash
set -e
docker build --build-arg FROM_SOURCE=ghcr.io/geek-cookbook/mkdocs-material-insiders . -t funkypenguin/mkdocs-material --platform amd64
docker run --rm --name mkdocs-material -e ENABLE_PDF_EXPORT=1 -v ${PWD}:/docs funkypenguin/mkdocs-material build -f mkdocs-pdf-print.yml
