#!/bin/bash
docker run --rm --name mkdocs-material -it -p 8000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material
