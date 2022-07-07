ARG FROM_SOURCE=squidfunk/mkdocs-material
FROM ${FROM_SOURCE}

RUN apk add --no-cache py3-pip py3-pillow py3-cffi py3-brotli gcc musl-dev python3-dev pango build-base libffi-dev jpeg-dev libxslt-dev

RUN pip install \
        mkdocs-autolinks-plugin \
        mkdocs-htmlproofer-plugin \
	mkdocs-git-revision-date-localized-plugin \
        mkdocs-macros-plugin \
        mkdocs-git-committers-plugin-2 \
        mkdocs-meta-descriptions-plugin \
        mkdocs-with-pdf

# Theoretically this could add support for headless chrome
RUN apk add --no-cache \
      chromium \
      nss \
      freetype \
      harfbuzz \
      ca-certificates \
      ttf-freefont \
      nodejs \
      yarn
