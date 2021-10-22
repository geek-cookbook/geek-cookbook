---
description: Gollum - A recipe for your own git-based wiki. My preciousssss
---

# Gollum

Gollum is a simple wiki system built on top of Git. A Gollum Wiki is simply a git repository (_either bare or regular_) of a specific nature:

* A Gollum repository's contents are human-editable, unless the repository is bare.
* Pages are unique text files which may be organized into directories any way you choose.
* Other content can also be included, for example images, PDFs and headers/footers for your pages.

Gollum pages:

* May be written in a variety of markups.
* Can be edited with your favourite system editor or IDE (_changes will be visible after committing_) or with the built-in web interface.
* Can be displayed in all versions (_commits_).

![Gollum Screenshot](../images/gollum.png)

As you'll note in the (_real world_) screenshot above, my requirements for a personal wiki are:

* Portable across my devices
* Supports images
* Full-text search
* Supports inter-note links
* Revision control

Gollum meets all these requirements, and as an added bonus, is extremely fast and lightweight.

!!! note
    Since Gollum itself offers no user authentication, this design secures gollum behind [traefik-forward-auth](/ha-docker-swarm/traefik-forward-auth/), so that in order to gain access to the Gollum UI at all, authentication must have already occurred.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need an empty git repository in /var/data/gollum for our data:

```bash
mkdir /var/data/gollum
cd /var/data/gollum
git init
```
### Prepare environment

1. Create `/var/data/config/gollum/gollum.env`, and populate with the following variables (_you can make the cookie secret whatever you like_)

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  app:
    image: dakue/gollum
    volumes:
     - /var/data/gollum:/gollum
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        # traefik common
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:gollum.example.com
        - traefik.port=4567     

        # traefikv2
        - "traefik.http.routers.gollum.rule=Host(`gollum.example.com`)"
        - "traefik.http.services.gollum.loadbalancer.server.port=4567"
        - "traefik.enable=true"

        # Remove if you wish to access the URL directly
        - "traefik.http.routers.wekan.middlewares=forward-auth@file"
    command: |
      --allow-uploads
      --emoji
      --user-icons gravatar

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.9.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Gollum stack

Launch the Gollum stack by running ```docker stack deploy gollum -c <path-to-docker-compose.yml>```

[^1]: In the current implementation, Gollum is a "single user" tool only. The contents of the wiki are saved as markdown files under /var/data/gollum, and all the git commits are currently "Anonymous"

--8<-- "recipe-footer.md"
