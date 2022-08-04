---
title: Install rutorrent / rtorrent in Docker
description: ruTorrent (looks like uTorrent) is a popular web UI frontend to rtorrent, the de-facto ncurses-based CLI torrent client. And it's a handy addition to our Autopirate Docker Swarm stack!
---

# RTorrent / ruTorrent in Autopirate Docker Swarm stack

!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

[RTorrent](http://rakshasa.github.io/rtorrent) is a popular CLI-based bittorrent client, and [ruTorrent](https://github.com/Novik/ruTorrent) is a powerful web interface for rtorrent.

![Rtorrent Screenshot](/images/rtorrent.png){ loading=lazy }

## Choose incoming port

When using a torrent client from behind NAT (_which swarm, by nature, is_), you typically need to set a static port for inbound torrent communications. In the example below, I've set the port to 36258. You'll need to configure `/var/data/autopirate/rtorrent/rtorrent/rtorrent.rc` with the equivalent port.

## Inclusion into AutoPirate

To include ruTorrent in your [AutoPirate](/recipes/autopirate/) stack, include something like the following example in your `autopirate.yml` docker-compose stack definition file:

```yaml
rtorrent:
  image: lscr.io/linuxserver/rutorrent
  env_file : /var/data/config/autopirate/rtorrent.env
  ports:
   - 36258:36258
  volumes:
   - /var/data/media/:/media
   - /var/data/autopirate/rtorrent:/config
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:rtorrent.example.com
      - "traefik.http.services.linx.loadbalancer.server.port=80"
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.rtorrent.rule=Host(`rtorrent.example.com`)"
      - "traefik.http.routers.rtorrent.entrypoints=https"
      - "traefik.http.services.rtorrent.loadbalancer.server.port=80"
      - "traefik.http.routers.rtorrent.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"
