#!/bin/bash
# This script prepares mkdocs for a build (there are some adjustments to be made to the recipes before publishing)

# Fetch git history so that we get last-updated timestamps
git fetch --unshallow

# # install mkdocs (or insiders version, if we're passed a GH_TOKEN var)
# if [ -z "$GH_TOKEN" ]
# then
#   pip install mkdocs-material
# else
  pip install git+https://${GH_TOKEN}@github.com/squidfunk/mkdocs-material-insiders.git
# fi

# Run python build script
python3 scripts/build.py mkdocs.yml

# Now build the docs for publishing
mkdocs build -f mkdocs.yml

# Setup any necessary netlify redirects
cp netlify_redirects.txt site/_redirects
