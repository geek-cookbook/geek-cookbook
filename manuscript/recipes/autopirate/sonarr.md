---
title: How to setup Sonarr v3 in Docker
description: Sonarr is a tool for finding, downloading and managing TV series*, and is a valuable addition to the docker-swarm AutoPirate stack
---

# Sonarr in Autopirate Docker Swarm stack

!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[Sonarr](https://sonarr.tv/) is a tool for finding, downloading and managing your TV series.

![Sonarr Screenshot](/images/sonarr.png){ loading=lazy }

## Inclusion into AutoPirate

To include Sonarr in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose v3 stack definition file:

```yaml
sonarr:
  image: lscr.io/linuxserver/sonarr:latest
  env_file : /var/data/config/autopirate/sonarr.env
  volumes:
   - /var/data/autopirate/sonarr:/config
   - /var/data/media:/media
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:sonarr.example.com
      - traefik.port=8989
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.sonarr.rule=Host(`sonarr.example.com`)"
      - "traefik.http.routers.sonarr.entrypoints=https"
      - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
      - "traefik.http.routers.sonarr.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"
