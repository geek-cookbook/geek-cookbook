#!/bin/bash
# This script prepares mkdocs for a build (there are some adjustments to be made to the recipes before publishing)

# Fetch git history so that we get last-updated timestamps
# git fetch --unshallow

# Run python build script to check for errors
# python3 scripts/build.py mkdocs.yml

# install mkdocs (or insiders version, if we're passed a GH_TOKEN var)
if [ -z "$GH_TOKEN" ]
then
  pip install mkdocs-material
  mkdocs build -f mkdocs.yml
else
  # Bypass search issue described at https://github.com/squidfunk/mkdocs-material/issues/3053
  git clone --depth 1 https://${GH_TOKEN}@github.com/squidfunk/mkdocs-material-insiders.git
  pip install -e mkdocs-material-insiders  
  mkdocs build -f mkdocs-insiders.yml
fi