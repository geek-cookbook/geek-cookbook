#!/bin/bash
docker build . -t funkypenguin/mkdocs-material
docker run --rm --name mkdocs-material -it -p 8000:8000 -v ${PWD}:/docs funkypenguin/mkdocs-material
