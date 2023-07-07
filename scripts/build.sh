#!/bin/bash
# This script prepares mkdocs for a build (there are some adjustments to be made to the recipes before publishing)

# Fetch git history so that we get last-updated timestamps
# git fetch --unshallow

set -e # abort on fail
set -x # debug failed builds

# Run python build script to check for errors
# python3 scripts/build.py mkdocs.yml

# install mkdocs (or insiders version, if we're passed a GH_TOKEN var)
if [ -z "$GH_TOKEN" ]
then
  echo "No GH_TOKEN passed, doing a normal build.."
  pip install mkdocs-material
  ENABLE_PDF_EXPORT=0 mkdocs build -f mkdocs.yml
else
  echo "GH_TOKEN passed, doing an insiders build.."
  pip install git+https://${GH_TOKEN}@github.com/squidfunk/mkdocs-material-insiders.git
  ENABLE_PDF_EXPORT=1 mkdocs build -f mkdocs-insiders.yml

  # Put the PDF into secret location
  mkdir -p site/${PDF_PATH}
  mv site/funkypenguins-geek-cookbook.pdf site/${PDF_PATH}/
fi

# Setup any necessary netlify redirects
cp netlify_redirects.txt site/_redirects

