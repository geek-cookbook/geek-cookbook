---
title: Run Jellyfin in Docker with docker compose / swarm
description: Jellyfin is best described as "like Emby but really FOSS"
recipe: Jellyfin
slug: Jellyfin
---

# Jellyfin

{% include 'try-in-elfhosted.md' %}

[Jellyfin](https://jellyfin.org/) is best described as "_like [Emby][emby] but really [FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software)_".

![Jellyfin Screenshot](../images/jellyfin.png){ loading=lazy }

If it looks very similar as Emby, is because it started as a fork of it, but it has evolved since them. For a complete explanation of the why, look [here](https://jellyfin.org/docs/general/about.html).

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need a location to store Jellyfin's library data, config files, logs and temporary transcoding space, so create ``/var/data/jellyfin``, and make sure it's owned by the user and group who also own your media data.

```bash
mkdir /var/data/jellyfin
```

Also if we want to avoid the cache to be part of the backup, we should create a location to map it on the runtime folder. It also has to be owned by the user and group who also own your media data.

```bash
mkdir /var/data/runtime/jellyfin
```

### Prepare {{ page.meta.recipe }} environment

Create jellyfin.env, and populate with PUID/GUID for the user who owns the /var/data/jellyfin directory (_above_) and your actual media content (_in this example, the media content is at **/srv/data**_)

```bash
PUID=
GUID=
```

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml
version: "3.0"

services:
  jellyfin:
    image: jellyfin/jellyfin
    env_file: /var/data/config/jellyfin/jellyfin.env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/data/jellyfin:/config
      - /var/data/runtime/jellyfin:/cache
      - /var/data/jellyfin/jellyfin:/config
      - /srv/data/:/data
    deploy:
      labels:
        # traefik common
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:jellyfin.example.com
        - traefik.port=8096     

        # traefikv2
        - "traefik.http.routers.jellyfin.rule=Host(`jellyfin.example.com`)"
        - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
        - "traefik.enable=true"

    networks:
        - traefik_public
    ports:
      - 8096:8096

networks:
  traefik_public:
    external: true
```

--8<-- "reference-networks.md"

## Serving

### Launch Jellyfin stack

Launch the stack by running ```docker stack deploy jellyfin -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, and complete the wizard-based setup to complete deploying your Jellyfin.

[^1]: I didn't use an [oauth2_proxy](/reference/oauth_proxy/) for this stack, because it would interfere with mobile client support.
[^2]: Got an NVIDIA GPU? See [this blog post](https://www.funkypenguin.co.nz/note/gpu-transcoding-with-emby-plex-using-docker-nvidia/) re how to use your GPU to transcode your media!
[^3]: We don't bother exposing the HTTPS port for Jellyfin, since [Traefik](/docker-swarm/traefik/) is doing the SSL termination for us already.

--8<-- "recipe-footer.md"
