---
title: Install Prowlarr in Docker
description: Prowlarr aggregates nzb/torrent searches. Imagine NZBHydra and Jackett had a baby, but it came out Arrr. Here's how you install Prowlarr into the Docker Swarm Autopirate stack
slug: Prowlarr
---

# Prowlarr in Autopirate Docker Swarm stack

{% include 'try-in-elfhosted.md' %}

!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[Prowlarr](https://github.com/Prowlarr/Prowlarr) is an indexer manager/proxy built on the popular arr .net/reactjs base stack to integrate with your various PVR apps.

Prowlarr supports management of both Torrent Trackers and Usenet Indexers. It integrates seamlessly with [Lidarr][lidarr], [Mylar3][mylar], [Radarr][radarr], [Readarr][readarr], and [Sonarr][sonarr] offering complete management of your indexers with no per app Indexer setup required!

![Prowlarr Screenshot](/images/prowlarr.png){ loading=lazy }

Fancy features include:

* Usenet support for 24 indexers natively, including Headphones VIP, and support for any Newznab compatible indexer via "Generic Newznab"
* Torrent support for over 500 trackers with more added all the time
* Torrent support for any Torznab compatible tracker via "Generic Torznab"
* Indexer Sync to Sonarr/Radarr/Readarr/Lidarr/Mylar3, so no manual configuration of the other applications are required
* Indexer history and statistics
* Manual searching of Trackers & Indexers at a category level
* Support for pushing releases directly to your download clients from Prowlarr
* Indexer health and status notifications
* Per Indexer proxy support (SOCKS4, SOCKS5, HTTP, Flaresolverr)

## Inclusion into AutoPirate

To include Prowlarr in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose stack definition file:

```yaml
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:nightly
    env_file: /var/data/config/prowlarr/prowlarr.env
    volumes:
      - /var/data/media/:/media
      - /var/data/prowlarr:/config
    deploy:
      replicas: 1
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:prowlarr.example.com
        - traefik.port=9696
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true        

        # traefikv2
        - "traefik.http.routers.prowlarr.rule=Host(`prowlarr.example.com`)"
        - "traefik.http.routers.prowlarr.entrypoints=https"
        - "traefik.http.services.prowlarr.loadbalancer.server.port=9696"
        - "traefik.http.routers.prowlarr.middlewares=forward-auth"
    networks:
      - internal
      - autopiratev2_public 
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"

## Prowlarr vs Jackett

Prowlarr and [Jackett][jackett] perform similar roles (*they help you aggregate indexers*), but Prowlarr includes the following advantages over Jackett:

1. Prowlarr can search both Usenet **and** Torrent indexers
2. Given app API keys, Prowlarr can auto-configuer your Arr apps, adding its indexers. Prowlarr currently auto-configures [Radarr][radarr], [Sonarr][sonarr], [Lidarr][lidarr], [Mylar][mylar], [Readarr][Readarr], and [LazyLibrarian][lazylibrarian]
3. Prowlarr can integrate with Flaresolverr to make it possible to query indexers behind Cloudflare "are-you-a-robot" protection, which would otherwise not be possible.

--8<-- "recipe-footer.md"

[^1]: Because Prowlarr is so young (*just a little kitten! :cat:*), there is no `:latest` image tag yet, so we're using the `:nightly` tag instead. Don't come crying to me if baby-Prowlarr bites your ass!
