---
title: Install funkwhale with docker-compose / swarm
description: Funkwhale is a decentralized, federated music streaming platform
recipe: Funkywhale
---

# Funkwhale

[Funkwhale](https://funkwhale.audio) is a decentralized, federated, and open music streaming / sharing platform. Think of it as "Mastodon for music".

![Funkwhale Screenshot](../images/funkwhale.jpg)

The idea is that you run a "pod" (*just like whales, Funkwhale users gather in pods*).  A pod is a website running the Funkwhale server software. You join the network by registering an account on a pod (*sometimes called "server" or "instance"*), which will be your home.

You will be then able to interact with other people regardless of which pod they are using.

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

First we create a directory to hold our funky data:

```bash
mkdir /var/data/funkwhale
```

### Prepare {{ page.meta.recipe }} environment

Funkwhale is configured using environment variables. Create `/var/data/config/funkwhale/funkwhale.env`, by running something like this:

```bash
mkdir -p /var/data/config/funkwhale/
cat > /var/data/config/funkwhale/funkwhale.env << EOF
# Replace 'funkwhale.example.com' with your actual domain
FUNKWHALE_HOSTNAME=funkwhale.example.com
# Protocol may also be: http
FUNKWHALE_PROTOCOL=https
# This limits the upload size
NGINX_MAX_BODY_SIZE=100M
# Bind to localhost
FUNKWHALE_API_IP=127.0.0.1
# Container port you want to expose on the host
FUNKWHALE_API_PORT=80
# Generate and store a secure secret key for your instance
DJANGO_SECRET_KEY=$(openssl rand -hex 45)
# Remove this if you expose the container directly on ports 80/443
NESTED_PROXY=1
# adapt to the pid/gid that own /var/data/funkwhale/
PUID=1000
PGID=1000
EOF
# reduce permissions on the .env file since it contains sensitive data
chmod 600 /var/data/funkwhale/funkwhale.env  
```

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3) (*I store all my config files as `/var/data/config/<stack name\>/<stack name\>.yml`*), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3.2" # https://docs.docker.com/compose/compose-file/compose-versioning/#version-3

services:
  funkwhale:
    image: funkwhale/all-in-one:1.0.1
    env_file: /var/data/config/funkwhale/funkwhale.env
    volumes:
      - /var/data/funkwhale/:/data/
      - /path/to/your/music/dir:/music:ro
    deploy:
      labels:
        # traefik common
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"

        # traefikv1
        - "traefik.frontend.rule=Host:funkwhale.example.com"
        - "traefik.port=80"

        # traefikv2
        - "traefik.http.routers.linx.rule=Host(`funkwhale.example.com`)"
        - "traefik.http.routers.linx.entrypoints=https"
        - "traefik.http.services.linx.loadbalancer.server.port=80" 
    networks:
      - traefik_public

networks:
  traefik_public:
    external: true
```

## Serving

### Unleash the Whale! 🐳

Launch the Funkwhale stack by running `docker stack deploy funkwhale -c <path -to-docker-compose.yml>`, and then watch the container logs using `docker stack logs funkywhale_funkywhale<tab-completion-helps>`.

You'll know the container is ready when you see an ascii version of the Funkwhale logo, followed by:

```bash
[2021-01-27 22:52:24 +0000] [411] [INFO] ASGI 'lifespan' protocol appears unsupported.
[2021-01-27 22:52:24 +0000] [411] [INFO] Application startup complete.
```

The first time we run Funkwhale, we need to setup the superuser account.

!!! tip
    If you're running a multi-node swarm, this next step needs to be executed on the node which is currently running Funkwhale. Identify this with `docker stack ps funkwhale`

Run something like the following:

```bash
docker exec -it funkwhale_funkwhale.1.<tab-completion-helps-here\> \
  manage createsuperuser \
  --username admin \
  --email <your admin email address\>
```

You'll be prompted to enter the admin password - here's some sample output:

```bash
root@swarm:~# docker exec -it funkwhale_funkwhale.1.gnx96tfr0lgmx5u3e8x4tkags \
  manage createsuperuser \
  --username admin \
  --email admin@funkypenguin.co.nz
2021-01-27 22:44:01,953 funkwhale_api.config INFO     Running with the following plugins enabled: funkwhale_api.contrib.scrobbler
Password:
Password (again):
Superuser created successfully.
root@swarm:~#
```

[^1]: Since the whole purpose of media sharing is to share **publically**, and Funkwhale includes robust user authentication, this recipe doesn't employ traefik-based authentication using [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/).
[^2]: These instructions are an opinionated simplication of the official instructions found at <https://docs.funkwhale.audio/installation/docker.html>
[^3]: It should be noted that if you import your existing media, the files will be **copied** into Funkwhale's data folder. There doesn't seem to be a way to point Funkwhale at an existing collection and have it just play it from the filesystem. To this end, be prepared for double disk space usage if you plan to import your entire music collection!
[^5]: No consideration is given at this point to backing up the Funkwhale data. Post a comment below if you'd like to see a backup container added!

--8<-- "recipe-footer.md"
