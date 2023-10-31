---
title: Install Heimdall Dashboard with Docker
description: Heimdall is a beautiful dashboard for all your web applications, and is a perfect combination your self-hosted Docker applications!
---
# Heimdall in Autopirate Docker Swarm stack

!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[Heimdall Application Dashboard](https://heimdall.site/) is a dashboard for all your web applications. It doesn't need to be limited to applications though, you can add links to anything you like.

Heimdall provides a single URL to manage access to all of your autopirate tools, and includes "enhanced" (_i.e., display stats within Heimdall without launching the app_) access to [NZBGet][nzbget], [SABnzbd][sabnzbd], and friends.

![Heimdall Screenshot](/images/heimdall.jpg)

## Inclusion into AutoPirate

To include Heimdall in your [AutoPirate](/recipes/autopirate/) stack, include the following example in your autopirate.yml docker-compose stack definition file:

```yaml
  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    env_file: /var/data/config/autopirate/heimdall.env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/data/heimdall:/config
    networks:
      - internal
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:heimdall.example.com
        - traefik.port=80
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true        

        # traefikv2
        - "traefik.http.routers.heimdall.rule=Host(`heimdall.example.com`)"
        - "traefik.http.routers.heimdall.entrypoints=https"
        - "traefik.http.services.heimdall.loadbalancer.server.port=80"
        - "traefik.http.routers.heimdall.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
{% include 'recipe-footer.md' %}

[^2:] The inclusion of Heimdall was due to the efforts of @gkoerk in our [Discord server](http://chat.funkypenguin.co.nz). Thanks gkoerk!
