---
title: How to install Lidarr (Music arr tool) in Docker
description: Lidarr is an automated music downloader for NZB and Torrent
---
# Lidarr in Autopirate Docker Swarm stack

!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[Lidarr](https://lidarr.audio/) is an automated music downloader for NZB and Torrent. It performs the same function as [Headphones](/recipes/autopirate/headphones), but is written using the same(ish) codebase as [Radarr][radarr] and [Sonarr][sonarr]. It's blazingly fast, and includes beautiful album/artist art. Lidarr supports [SABnzbd][sabnzbd], [NZBGet][nzbget], Transmission, µTorrent, Deluge and Blackhole (_just like Sonarr / Radarr_)

![Lidarr Screenshot](../../images/lidarr.png)

## Inclusion into AutoPirate

To include Lidarr in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose stack definition file:

````yaml
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    env_file: /var/data/config/lidarr/lidarr.env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/data/media:/media
      - /var/data/lidarr:/config
    deploy:
      replicas: 1
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:lidarr.example.com
        - traefik.port=8686
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true        

        # traefikv2
        - "traefik.http.routers.lidarr.rule=Host(`lidarr.example.com`)"
        - "traefik.http.routers.lidarr.entrypoints=https"
        - "traefik.http.services.lidarr.loadbalancer.server.port=8686"
        - "traefik.http.routers.lidarr.middlewares=forward-auth"
````

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"

## Lidarr vs Headphones

Lidarr and [Headphones][headphones] perform the same basic function. The primary difference, from what I can tell, is that Lidarr is build on the Arr stack, and so plays nicely with [Prowlarr][prowlarr].

## Integrate Lidarr with Beets

I've not tried this yet, but it seems that it's possible to [integrate Lidarr with Beets](https://www.reddit.com/r/Lidarr/comments/rahcer/my_lidarrbeets_automation_setup/)

--8<-- "recipe-footer.md"
