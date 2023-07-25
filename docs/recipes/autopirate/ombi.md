---
title: Run Ombi in Docker (protecting the API with SSL)
description: Ombi is like your media butler - it recommends, finds what you want to watch! It includes a rich API, and since it's behind our traefik proxy, it inherits the same automatic SSL certificate generation as the rest of the Autopirate Docker Swarm stack.
slug: Ombi
---

# Ombi in Autopirate Docker Swarm stack

{% include 'try-in-elfhosted.md' %}

!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[Ombi](https://github.com/tidusjar/Ombi) is a useful addition to the [autopirate][autopirate]stack. Features include:

* Lets users request Movies and TV Shows (_whether it being the entire series, an entire season, or even single episodes._)
* Easily manage your requests
User management system (_supports plex.tv, Emby and local accounts_)
* A landing page that will give you the availability of your [Plex][plex]/[Emby][emby]/[Jellyfin][jellyfin] server and also add custom notification text to inform your users of downtime.
* Allows your users to get custom notifications!
* Will show if the request is already on plex or even if it's already monitored.
* Automatically updates the status of requests when they are available on Plex/Emby/Jellyfin

![Ombi Screenshot](/images/ombi.png){ loading=lazy }

## Inclusion into AutoPirate

To include Ombi in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose stack definition file:

```yaml
ombi:
  image: lscr.io/linuxserver/ombi:latest
  env_file : /var/data/config/autopirate/ombi.env
  volumes:
   - /var/data/autopirate/ombi:/config
  networks:
  - internal

ombi_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/ombi.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:ombi.example.com
      - traefik.port=3579
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.ombi.rule=Host(`ombi.example.com`)"
      - "traefik.http.routers.ombi.entrypoints=https"
      - "traefik.http.services.ombi.loadbalancer.server.port=3579"
      - "traefik.http.routers.ombi.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"
