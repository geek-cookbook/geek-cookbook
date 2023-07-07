#!/bin/bash
docker pull ghcr.io/geek-cookbook/mkdocs-material-insiders
docker build --build-arg FROM_SOURCE=ghcr.io/geek-cookbook/mkdocs-material-insiders . -t funkypenguin/mkdocs-material
docker run --rm --name mkdocs-material -v ${PWD}:/docs funkypenguin/mkdocs-material build -f mkdocs-insiders.yml
