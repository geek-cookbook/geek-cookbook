#FROM squidfunk/mkdocs-material
FROM ghcr.io/squidfunk/mkdocs-material-insiders
RUN pip install \
        mkdocs-autolinks-plugin \
        mkdocs-htmlproofer-plugin \
	mkdocs-git-revision-date-localized-plugin \
        mkdocs-macros-plugin
