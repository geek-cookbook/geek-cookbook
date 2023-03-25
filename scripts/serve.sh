#!/bin/bash
# docker pull squidfunk/mkdocs-material:latest
# docker build . -t funkypenguin/mkdocs-material
docker run --rm --name mkdocs-material -it -p 8123:8000 -v ${PWD}:/docs -e PROD_BUILD=false ghcr.io/geek-cookbook/mkdocs-material:master serve \
    --dev-addr 0.0.0.0:8000 \
    --dirtyreload
