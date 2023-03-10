---
description: Geeky RSS reader
recipe: Tiny Tiny RSS
title: Run Tiny Tiny RSS in Docker Swarm
---

# Tiny Tiny RSS

[Tiny Tiny RSS](https://tt-rss.org/) is a self-hosted, AJAX-based RSS reader, which rose to popularity as a replacement for Google Reader. It supports ~~geeky~~ advanced features, such as:

* Plugins and themeing in a drop-in fashion
* Filtering (discard all articles with title matching "trump")
* Sharing articles via a unique public URL/feed

![Tiny Tiny RSS Screenshot](../images/tiny-tiny-rss.png){ loading=lazy }

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/ttrss:

```bash
mkdir /var/data/ttrss
cd /var/data/ttrss
mkdir -p {database,database-dump}
mkdir /var/data/config/ttrss
cd /var/data/config/ttrss
```

### Prepare {{ page.meta.recipe }} environment

Create `/var/data/config/ttrs/ttrss.env`, and populate with the following variables, customizing at least the database password (POSTGRES_PASSWORD **and** DB_PASS) and the TTRSS_SELF_URL to point to your installation.

```yaml
# Variables for postgres:latest
POSTGRES_USER=ttrss
POSTGRES_PASSWORD=mypassword
DB_EXTENSION=pg_trgm

# Variables for pg_dump running in postgres/latest (used for db-backup)
PGUSER=ttrss
PGPASSWORD=mypassword
PGHOST=db
BACKUP_NUM_KEEP=3
BACKUP_FREQUENCY=1d

# Variables for funkypenguin/docker-ttrss
DB_USER=ttrss
DB_PASS=mypassword
DB_PORT=5432
DB_PORT_5432_TCP_ADDR=db
DB_PORT_5432_TCP_PORT=5432
TTRSS_SELF_URL=https://ttrss.example.com
TTRSS_REPO=https://github.com/funkypenguin/tt-rss.git
S6_BEHAVIOUR_IF_STAGE2_FAILS=2
```

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
    db:
      image: postgres:latest
      env_file: /var/data/config/ttrss/ttrss.env
      volumes:
        - /var/data/ttrss/database:/var/lib/postgresql/data
      networks:
        - internal

    app:
      image: funkypenguin/docker-ttrss
      env_file: /var/data/config/ttrss/ttrss.env
      deploy:
        labels:
          # traefik common
          - traefik.enable=true
          - traefik.docker.network=traefik_public

          # traefikv1
          - traefik.frontend.rule=Host:ttrss.example.com
          - traefik.port=8080     

          # traefikv2
          - "traefik.http.routers.ttrss.rule=Host(`ttrss.example.com`)"
          - "traefik.http.services.ttrss.loadbalancer.server.port=8080"
          - "traefik.enable=true"
      networks:
        - internal
        - traefik_public

    db-backup:
      image: postgres:latest
      env_file: /var/data/config/ttrss/ttrss.env
      volumes:
        - /var/data/ttrss/database-dump:/dump
        - /etc/localtime:/etc/localtime:ro
      entrypoint: |
        bash -c 'bash -s <<EOF
        trap "break;exit" SIGHUP SIGINT SIGTERM
        sleep 2m
        while /bin/true; do
          pg_dump -Fc > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.psql
          (ls -t /dump/dump*.psql|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.psql)|sort|uniq -u|xargs rm -- {}
          sleep $$BACKUP_FREQUENCY
        done
        EOF'
      networks:
      - internal

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.5.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch TTRSS stack

Launch the TTRSS stack by running ```docker stack deploy ttrss -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN** - the first user you create will be an administrative user.

--8<-- "recipe-footer.md"
