---
title: Run Audiobookshelf app in Docker
description: Audiobookshelf is a self-hosted audiobook and podcast server, with native Android and iOS (Testflight) apps, supporting offline syncing
slug: Audiobookshelf
---

# Audiobookshelf in Docker Swarm

{% include 'try-in-elfhosted.md' %}

[Audiobookshelf](https://www.audiobookshelf.org/) is a powerful audiobook / podcast streaming server, whose strength lies in its native app support on [Android](https://play.google.com/store/apps/details?id=com.audiobookshelf.app) / [iOS](https://testflight.apple.com/join/wiic7QIW) (*Testflight required*).

![Audiobookshelf Screenshot](/images/audiobookshelf.png){ loading=lazy }

Features include:

* Fully open-source, including the [android & iOS app](https://github.com/advplyr/audiobookshelf-app) (in beta)
* Stream all audio formats on the fly
* Search and add podcasts to download episodes w/ auto-download
* Multi-user support w/ custom permissions
* Keeps progress per user and syncs across devices
* Auto-detects library updates, no need to re-scan
* Upload books and podcasts w/ bulk upload drag and drop folders
* Backup your metadata + automated daily backups
* Progressive Web App (PWA)
* Chromecast support on the web app and android app
* Fetch metadata and cover art from several sources
* Basic ebook support and e-reader (*experimental*)
* Merge your audio files into a single m4b w/ metadata and embedded cover (experimental)

The developers are actively making improvements (*as evidenced by the [audiobookserver github repo](https://github.com/advplyr/audiobookshelf)!*), and welcome suggestions. There's even a [Discord server](https://discord.gg/pJsjuNCKRq)!

## Audiobookshelf requirements

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your auth host (*"audiobookshelf.yourdomain.com" is a good choice*), pointed to your [keepalived](/docker-swarm/keepalived/) IP

### Setup data locations

First, we create a directory to hold the metadata and config (*Audiobookshelf docs indicate that these should be separate directories*):

```bash
mkdir /var/data/audiobookshelf/metadata
mkdir /var/data/audiobookshelf/config
```

### Setup environment

It's helpful to keep environment variables in a separate file, so create `/var/data/config/audiobookshelf/audiobookshelf.env`, as follows (*you may want to customise the UID/GID to match those of your media folder*):

```text
AUDIOBOOKSHELF_UID=99
AUDIOBOOKSHELF_GID=100
```

### Audiobookshelf Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below.. example:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/audiobookshelf/audiobookshelf.yml"
version: '3'

services:
  app:
    image: advplyr/audiobookshelf
    env_file: /var/data/config/audiobookshelf/audiobookshelf.env
    volumes:
      - /var/data/audiobookshelf/config:/config
      - /var/data/audiobookshelf/metadata:/metadata
      # Set this next volume to wherever you store your audiobook library. 
      # You can define multiple libraries within this folder, like `/media/audio/podcasts`, `/media/audio/audiobooks`, etc
      - /var/data/media:/media
    deploy:
      replicas: 1      
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:audiobookshelf.example.com
        - traefik.port=80       

        # traefikv2
        - "traefik.http.routers.audiobookshelf.rule=Host(`audiobookshelf.example.com`)"
        - "traefik.http.routers.audiobookshelf.entrypoints=https"
        - "traefik.http.services.audiobookshelf.loadbalancer.server.port=80"

    networks:
      - traefik_public
      
networks:
  traefik_public:
    external: true
```

!!! question "Should we use Traefik Forward Auth?"
    No, because (a) the mobile apps won't work with session/cookie based auth, and (b) the docs indicate that using middleware which alters CORS with Traefik will cause the app to error!

## Run Audiobookshelf

Launch the audiobookshelf stack by running ```docker stack deploy audiobookshelf -c <path -to-docker-compose.yml>```

### Setup audiobookshelf

Now hit the URL you created for Audiobookshelf, and you'll find yourself presented with the "Initial Server Setup". After creating a user and password, setup your libraries, and then either stream your audio directly in your browser, or fire up the [Android](https://play.google.com/store/apps/details?id=com.audiobookshelf.app) / [iOS app](https://testflight.apple.com/join/wiic7QIW) and listen on the go! [^1]

## Summary

What have we achieved? We can now easily consume our audio books / podcasts via Audiobookshelf, securely over our Traefik-exposed service! [^2]

!!! summary "Summary"
    Created:

    * [X] Audiobookshelf is running, able to access your media libraries, and is streaming books / podcasts to you, wherever you are! :book: :headphones:

[^1]: The apps also allow you to download entire books to your device, so that you can listen without being directly connected!
[^2]: Audiobookshelf pairs very nicely with [Readarr][readarr], and [Prowlarr][prowlarr], to automate your audio book sourcing and management!

{% include 'recipe-footer.md' %}
