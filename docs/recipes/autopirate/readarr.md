---
title: Run Readarr (Sonarr for books / audiobooks) in Docker
description: Readarr is "Sonarr/Radarr for eBooks and audiobooks, and plays perfectly with the rest of the Autopirate Docker Swarm stack"
slug: Readarr
---

# Readarr in Autopirate Docker Swarm stack

{% include 'try-in-elfhosted.md' %}

!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[Readarr](https://github.com/Readarr/Readarr), in the fine tradition of [Radarr][radarr] and [Sonarr][sonarr], is a tool for "sourcing" eBooks, using usenet or bittorrent indexers.

![Readarr Screenshot](/images/readarr.png){ loading=lazy }

Features include:

* Support for major platforms: Windows, Linux, macOS, Raspberry Pi, etc.
* Automatically detects new books
* Can scan your existing library and download any missing books
* Automatic failed download handling will try another release if one fails
* Manual search so you can pick any release or to see why a release was not downloaded automatically
* Fully configurable book renaming
* Full integration with [SABnzbd][sabnzbd] and [NZBGet][sabnzbd]
* Full integration with [Calibre][calibre-web] (add to library, conversion)
* And a beautiful UI!

## Inclusion into AutoPirate

To include Readarr in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose stack definition file:

```yaml
readarr:
  image: lscr.io/linuxserver/readarr:latest
  env_file : /var/data/config/autopirate/readarr.env
  volumes:
   - /var/data/autopirate/readarr:/config
   - /var/data/media/books:/books
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:readarr.example.com
      - traefik.port=8787
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.readarr.rule=Host(`readarr.example.com`)"
      - "traefik.http.routers.readarr.entrypoints=https"
      - "traefik.http.services.readarr.loadbalancer.server.port=8787"
      - "traefik.http.routers.readarr.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
{% include 'recipe-footer.md' %}
