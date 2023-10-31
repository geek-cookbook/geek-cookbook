---
title: Run Immich in Docker Swarm
description: How to install your own immich instance using Docker Swarm
---

# Immich in Docker Swarm

Immich is a promising self-hosted alternative to Google Photos. Its UI and features are clearly heavily inspired by Google Photos, and like [Photoprism][photoprism], Immich uses tensorflow-based machine learning to auto-tag your photos!

!!! warning "Pre-production warning"
    The developer makes it abundantly clear that Immich is under heavy development (*although it's covered by "wife-insurance"[^1]*), features and APIs may change, and all your photos may be lost, or (worse) auto-shared with your :dragon_face: mother-in-law! Take due care :wink:

![Immich Screenshot](/images/immich.jpg){ loading=lazy }

See my detailed review of Immich, as a Google Photos replacement, [here][review/immich]

## Immich requirements

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your Immich instance, pointed to your [keepalived](/docker-swarm/keepalived/) IP

### Setup data locations

First, we create a directory to hold the immich docker-compose configuration:

```bash
mkdir /var/data/config/immich
```

Then we setup directories to hold all the various data:

```bash
mkdir -p /var/data/immich/database-dump
mkdir -p /var/data/immich/upload
mkdir -p /var/data/runtime/immich/database
```

### Setup Immich environment

Create `/var/data/config/immich/immich.env` something like the example below..

```yaml title="/var/data/config/immich/immich.env"
###################################################################################
# Database
###################################################################################

# These are for the Immich components
DB_HOSTNAME=db
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE_NAME=immich

# These are specific to how the postgres image likes to receive its ENV vars
POSTGRES_PASSWORD=postgres
#POSTGRES_USER=postgres
POSTGRES_DB=immich

###################################################################################
# Redis
###################################################################################

REDIS_HOSTNAME=redis

# Optional Redis settings:
# REDIS_PORT=6379
# REDIS_DBINDEX=0
# REDIS_PASSWORD=
# REDIS_SOCKET=


###################################################################################
# JWT SECRET
###################################################################################

JWT_SECRET=randomstringthatissolongandpowerfulthatnoonecanguess # (1)!

###################################################################################
# MAPBOX
####################################################################################

# ENABLE_MAPBOX is either true of false -> if true, you have to provide MAPBOX_KEY
ENABLE_MAPBOX=false
MAPBOX_KEY=

###################################################################################
# WEB - Required
###################################################################################

# This is the URL of your vm/server where you host Immich, so that the web frontend
# know where can it make the request to.
# For example: If your server IP address is 10.1.11.50, the environment variable will
# be VITE_SERVER_ENDPOINT=http://10.1.11.50:2283/api
# !CAUTION! THERE IS NO FORWARD SLASH AT THE END

VITE_SERVER_ENDPOINT=https://immich.example.com/api


####################################################################################
# WEB - Optional
####################################################################################

# Custom message on the login page, should be written in HTML form.
# For example VITE_LOGIN_PAGE_MESSAGE="This is a demo instance of Immich.<br><br>Email: <i>demo@demo.de</i><br>Password: <i>demo</i>"

VITE_LOGIN_PAGE_MESSAGE=

NODE_ENV=production
```

1. Yes, this has to be long. At least 20 characters.

### Immich Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below.. example:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/immich/immich.yml"
version: "3.2"

services:
  immich-server:
    image: altran1502/immich-server:release
    entrypoint: ["/bin/sh", "./start-server.sh"]
    volumes:
      - /var/data/immich/upload:/usr/src/app/upload
    env_file: /var/data/config/immich/immich.env
    networks:
      - internal

  immich-microservices:
    image: altran1502/immich-server:release
    entrypoint: ["/bin/sh", "./start-microservices.sh"]
    volumes:
      - /var/data/immich/upload:/usr/src/app/upload
    env_file: /var/data/config/immich/immich.env
    networks:
      - internal

  immich-machine-learning:
    image: altran1502/immich-machine-learning:release
    entrypoint: ["/bin/sh", "./entrypoint.sh"]
    volumes:
      - /var/data/immich/upload:/usr/src/app/upload
    env_file: /var/data/config/immich/immich.env
    networks:
      - internal

  immich-web:
    image: altran1502/immich-web:release
    entrypoint: ["/bin/sh", "./entrypoint.sh"]
    env_file: /var/data/config/immich/immich.env
    networks:
      - internal

  redis:
    image: redis:6.2
    networks:
      - internal

  db:
    image: postgres:14
    env_file: /var/data/config/immich/immich.env
    volumes:
      - /var/data/runtime/immich/database:/var/lib/postgresql/data
    networks:
      - internal

  db-backup:
    image: postgres:14
    env_file: /var/data/config/immich/immich-db-backup.env
    volumes:
      - /var/data/immich/database-dump:/dump
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        pg_dump -Fc > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.psql
        ls -tr /dump/dump_*.psql | head -n -"$$BACKUP_NUM_KEEP" | xargs -r rm
        sleep $$BACKUP_FREQUENCY
      done
      EOF'
    networks:
      - internal

  immich-proxy:
    container_name: immich_proxy
    image: altran1502/immich-proxy:release
    ports:
      - 2283:80
    deploy:
      replicas: 1
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:immich.example.com
        - traefik.port=80

        # traefikv2
        - "traefik.http.routers.immich.rule=Host(`immich.example.com`)"
        - "traefik.http.routers.immich.entrypoints=https"
        - "traefik.http.services.immich.loadbalancer.server.port=80"        
    networks:
      - internal
      - traefik_public

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.8.0/24
```

--8<-- "reference-networks.md"

## Launch Immich!

Launch the Immich stack by running

```bash
docker stack deploy immich -c /var/data/config/immich/immich.yml
```

Now hit the URL you defined in your config, and you should be prompted to create your first (admin) account, after which you can login (*with the details you just created*), and start admin-ing. Install a mobile app, connect using the same credentials, and start backing up all your photos!

## Summary

What have we achieved? We have an HTTPS-protected endpoint to target with the native mobile apps, allowing us to backup photos from mobile devices and have them become searchable, shareable, and browseable via a beautiful, Google Photos-esque interface!

!!! summary "Summary"
    Created:

    * [X] Photos can be synced from mobile device, or manually uploaded via web UI

## Setup Immich in < 60s

Sponsors have access to a [Premix](/premix/) playbook, which will set up Immich in under 60s (*see below*):
<iframe width="560" height="315" src="https://www.youtube.com/embed/s-NZjYrNOPg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

{% include 'recipe-footer.md' %}

[^1]: "wife-insurance": When the developer's wife is a primary user of the platform, you can bet he'll be writing quality code! :woman: :material-karate: :man: :bed: :cry:
[^2]: There's a [friendly Discord server](https://discord.com/invite/D8JsnBEuKb) for Immich too!
