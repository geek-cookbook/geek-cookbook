FROM squidfunk/mkdocs-material
RUN pip install \
        mkdocs-autolinks-plugin \
        mkdocs-htmlproofer-plugin