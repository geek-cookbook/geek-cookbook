#!/bin/bash
docker pull ghcr.io/geek-cookbook/mkdocs-material-insiders
docker build --build-arg FROM_SOURCE=ghcr.io/geek-cookbook/mkdocs-material-insiders . -t funkypenguin/mkdocs-material-insiders
docker run --rm --name mkdocs-material -it -p 8123:8000 -v ${PWD}:/docs -e PROD_BUILD=false funkypenguin/mkdocs-material-insiders serve \
    --dev-addr 0.0.0.0:8000 \
    --dirtyreload \
    --config-file mkdocs-insiders.yml
