ARG FROM_SOURCE=squidfunk/mkdocs-material
FROM ${FROM_SOURCE}

RUN apk add --no-cache py3-pip py3-pillow py3-cffi py3-brotli gcc musl-dev python3-dev pango build-base libffi-dev jpeg-dev libxslt-dev pngquant py3-cairosvg

RUN pip install \
        beautifulsoup4==4.9.3 \
        mkdocs-autolinks-plugin \
        mkdocs-htmlproofer-plugin \
	mkdocs-git-revision-date-localized-plugin \
        mkdocs-macros-plugin \
        mkdocs-git-committers-plugin-2 \
        mkdocs-meta-descriptions-plugin \
        mkdocs-with-pdf \
        mkdocs-extra-sass-plugin \
        mkdocs-rss-plugin \
        qrcode \
        livereload

# # Theoretically this could add support for headless chrome
# RUN apk add --no-cache \
#       chromium \
#       nss \
#       freetype \
#       harfbuzz \
#       ca-certificates \
#       ttf-freefont \
#       nodejs \
#       yarn ttf-ubuntu-font-family dbus yarn


RUN   git config --global --add safe.directory /docs

 # Additional font 
#  COPY fonts /usr/share/fonts/Additional 
#  RUN apk --update --upgrade --no-cache add fontconfig ttf-freefont font-noto terminus-font \ 
#      && fc-cache -f \ 
#      && fc-list | sort 
