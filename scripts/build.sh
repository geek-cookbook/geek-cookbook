#!/bin/bash
# This script prepares mkdocs for a build (there are some adjustments to be made to the recipes before publishing)

# Fetch git history so that we get last-updated timestamps
git fetch --unshallow

# Run python build script
python3 scripts/build.py mkdocs.yml

# Now build the docs for publishing
mkdocs build -f mkdocs.yml

# Setup any necessary netlify redirects
cp netlify_redirects.txt site/_redirects