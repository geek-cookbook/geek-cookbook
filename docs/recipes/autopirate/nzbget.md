---
title: How to download from usenet using NZBGet in Docker
description: NZBGet is a tool for downloading "content" from Usenet providers, and is the workhorse of our Autopirate Docker Swarm stack
slug: NZBGet
---

# NZBGet in Autopirate Docker Swarm stack

{% include 'try-in-elfhosted.md' %}

!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

## Introduction

NZBGet performs the same function as [SABnzbd][sabnzbd] (_downloading content from Usenet servers_), but it's lightweight and fast(er), written in C++ (_as opposed to Python_).

![NZBGet Screenshot](/images/nzbget.jpg)

## Inclusion into AutoPirate

To include NZBGet in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose stack definition file:

```yaml
nzbget:
  image: lscr.io/linuxserver/nzbget
  env_file : /var/data/config/autopirate/nzbget.env  
  volumes:
   - /var/data/autopirate/nzbget:/config
   - /var/data/media:/data
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:nzbget.example.com
      - traefik.port=6789
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.nzbget.rule=Host(`nzbget.example.com`)"
      - "traefik.http.routers.nzbget.entrypoints=https"
      - "traefik.http.services.nzbget.loadbalancer.server.port=6789"
      - "traefik.http.routers.nzbget.middlewares=forward-auth"
```

[^tfa]: Since we're relying on [Traefik Forward Auth][tfa] to protect us, we can just disable NZGet's own authentication, by changing ControlPassword to null in nzbget.conf (i.e. ```ControlPassword=```)

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
{% include 'recipe-footer.md' %}
