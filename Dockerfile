ARG FROM_SOURCE=squidfunk/mkdocs-material
FROM ${FROM_SOURCE}

RUN pip install \
        mkdocs-autolinks-plugin \
        mkdocs-htmlproofer-plugin \
	mkdocs-git-revision-date-localized-plugin \
        mkdocs-macros-plugin
