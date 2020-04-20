#!/bin/bash
docker pull squidfunk/mkdocs-material:5.1.1
docker build . -t funkypenguin/mkdocs-material
docker run --rm --name mkdocs-material -it -p 8123:8000 -v ${PWD}:/docs funkypenguin/mkdocs-material
