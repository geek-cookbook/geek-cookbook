---
title: Kavita Reader in Docker - Read ebooks / Manga / Comics
description: Here's a recipe to run Kavita under Docker Swarm to read your comics / manga / ebooks
---

# Kavita Reader in Docker Swarm

So you've just watched a bunch of superhero movies, and you're suddenly inspired to deep-dive into the weird world of comic books? You're already rocking [AutoPirate](/recipes/autopirate/) with [Mylar](/recipes/autopirate/mylar/) and [NZBGet](/recipes/autopirate/nzbget/) to grab content, but how to manage and enjoy your growing collection?

![Kavita Screenshot](/images/kavita.png){ loading=lazy }

[Kavita Reader](https://www.kavitareader.com) is a "*rocket fueled self-hosted digital library which supports a vast array of file formats*". Primarily used for cosuming Manga (*but quite capable of managing ebooks too*), Kavita's killer feature is an OPDS server for integration with other mobile apps such as [Chunky on iPad](https://apps.apple.com/us/app/chunky-comic-reader/id663567628), and the ability to save your reading position across multiple devices.

There's a [public demo available](https://www.kavitareader.com/#demo) too!

--8<-- "recipe-standard-ingredients.md"
    *[X] [AutoPirate](/recipes/autopirate/) components (*specifically [Mylar](/recipes/autopirate/mylar/)*), for searching for, downloading, and managing comic books

## Preparation

### Setup data locations

First we create a directory to hold the kavita database, logs and other persistent data:

```bash
mkdir /var/data/kavita
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/kavita.yml"
version: "3.2" # https://docs.docker.com/compose/compose-file/compose-versioning/#version-3

services:
  kavita:
    image: kizaing/kavita:latest
    env_file: /var/data/config/kavita/kavita.env
    volumes:
      - /var/data/kavita:/kavita/config
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:kavita.example.com
        - traefik.port=8000     

        # traefikv2
        - "traefik.http.routers.kavita.rule=Host(`kavita.example.com`)"
        - "traefik.http.routers.kavita.entrypoints=https"
        - "traefik.http.services.kavita.loadbalancer.server.port=5000" 
        
        # uncomment for traefik-forward-auth (1)
        # - "traefik.http.routers.radarr.middlewares=forward-auth"

        # uncomment for authelia (2)
        # - "traefik.http.routers.radarr.middlewares=authelia"

    networks:
      - traefik_public

networks:
  traefik_public:
    external: true
```

1. Uncomment to protect Kavita with an additional layer of authentication, using [Traefik Forward Auth][tfa]
2. Uncomment to protect Kavita with an additional layer of authentication, using [Authelia][authelia]

## Serving

### Avengers Assemble!

Launch the Kavita stack by running ```docker stack deploy kavita -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. Since it's a fresh installation, Kavita will prompt you to setup a username and password, after which you'll be able to setup your library, and tweak all teh butt0ns!

[^1]: Since Kavita doesn't need to communicate with any other local docker services, we don't need a separate overlay network for it. Provided Traefik can reach kavita via the `traefik_public` overlay network, we've got all we need.

[^2]: There's an [active subreddit](https://www.reddit.com/r/KavitaManga/) for Kavita

--8<-- "recipe-footer.md"
