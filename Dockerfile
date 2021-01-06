FROM squidfunk/mkdocs-material
RUN pip install \
        mkdocs-autolinks-plugin \
        mkdocs-htmlproofer-plugin \
	mkdocs-git-revision-date-localized-plugin && \
    adduser -D vscode
