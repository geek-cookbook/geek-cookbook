#!/bin/bash
# docker pull ghcr.io/geek-cookbook/mkdocs-material-insiders
docker build --build-arg FROM_SOURCE=funkypenguin/mkdocs-material-insiders . -t funkypenguin/mkdocs-material
docker run --rm --name mkdocs-material -it -p 8123:8000 -v ${PWD}:/docs funkypenguin/mkdocs-material serve -f mkdocs-insiders.yml --dev-addr 0.0.0.0:8000 --dirtyreload
