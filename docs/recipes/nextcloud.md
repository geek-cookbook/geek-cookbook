---
title: How to run Nextcloud in Docker (behind Traefik)
description: We can now run Nextcloud in our Docker Swarm, with LetsEncrypt SSL termination handled by Traefik
recipe: NextCloud
---

# NextCloud Docker Compose / Swarm Install

[NextCloud](https://nextcloud.com/) (*now called "[Nextcloud Hub II](https://nextcloud.com/blog/nextcloud-hub-2-brings-major-overhaul-introducing-nextcloud-office-p2p-backup-and-more/)"*) has as grown from a humble [fork of OwnCloud](https://owncloud.com/owncloud-vs-nextcloud/) in [2016](https://www.zdnet.com/article/owncloud-founder-forks-popular-open-source-cloud/), to an industry-leading, on-premises content collaboration platform. NextCloud still does the traditional file-collaboration, but is now beefed-up with an [app store](https://apps.nextcloud.com/featured) supporting more than 100 apps, including [text and video chats](https://apps.nextcloud.com/apps/spreed), [calendaring](https://apps.nextcloud.com/apps/calendar), a [mail client](https://apps.nextcloud.com/apps/mail), and even an [office editing suite](https://apps.nextcloud.com/apps/richdocuments).

It also now supports a sweet, customizable dashboard:

![NextCloud Screenshot](/images/nextcloud.png){ loading=lazy }

This recipe uses the official NextCloud docker hub image, and includes separate docker containers for the database (*MariaDB*), Redis (*for transactional locking*), automated database backup, (*you backup the stuff you care about, right?*) and a separate cron container for running NextCloud's 15-min background tasks.

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories for [static data](/reference/data_layout/#static-data) to bind-mount into our container, so create them in `/var/data/nextcloud` (_so that they can be [backed up](/recipes/duplicity/)_)

```bash
mkdir /var/data/nextcloud
cd /var/data/nextcloud
mkdir -p {html,apps,config,data,database-dump}
```

Now make **more** directories for [runtime data](/reference/data_layout/#runtime-data) (_so that they can be **not** backed-up_):

```bash
mkdir /var/data/runtime/nextcloud
cd /var/data/runtime/nextcloud
mkdir -p {db,redis}
```

### Nextcloud environment variables

Create `nextcloud.env`, and populate with the following variables

```bash title="/var/data/config/nextcloud/nextcloud.env"
MYSQL_HOST=db
OVERWRITEPROTOCOL=https
REDIS_HOST=redis # (1)!

# For MariaDB
MYSQL_ROOT_PASSWORD=iliketogethaxed
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=haxmebaby
```

1. Necessary to add Redis support

Now create a **separate** `nextcloud-db-backup.env` file, to capture the environment variables necessary to perform the backup. (_If the same variables are shared with the mariadb container, they [cause issues](https://forum.funkypenguin.co.nz/t/nextcloud-funky-penguins-geek-cookbook/254/3?u=funkypenguin) with database access_)

````bash title="/var/data/config/nextcloud/nextcloud-db-backup.env"
# For database backup (keep 7 days daily backups)
MYSQL_PWD=<set to something secure, same as MYSQL_ROOT_PASSWORD above>
MYSQL_USER=root
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
````

### Nextcloud Docker Compose

Create a docker swarm config file in docker-compose syntax (v3), something like the following example:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/nextcloud/nextcloud.yml"
version: "3.0"

services:
  nextcloud:
    image: nextcloud
    env_file: /var/data/config/nextcloud/nextcloud.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
      # traefik common
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:nextcloud.example.com
      - traefik.frontend.redirect.permanent=true
      - traefik.frontend.redirect.regex=https://(.*)/.well-known/(card|cal)dav
      - traefik.frontend.redirect.replacement=https://$$1/remote.php/dav/
      - traefik.port=80     

      # traefikv2
      - "traefik.http.routers.nextcloud.rule=Host(`nextcloud.example.com`)"
      - "traefik.http.services.nextcloud.loadbalancer.server.port=80"
      - "traefik.http.middlewares.nextcloud-redirectregex.redirectRegex.permanent=true"
      - "traefik.http.middlewares.nextcloud-redirectregex.redirectregex.regex=^https://(.*)/.well-known/(card|cal)dav"
      - "traefik.http.middlewares.nextcloud-redirectregex.redirectregex.replacement=https://$$1/remote.php/dav/"
      - "traefik.http.routers.nextcloud.middlewares=nextcloud-redirectregex@docker"

    volumes:
      - /var/data/nextcloud/html:/var/www/html
      - /var/data/nextcloud/apps:/var/www/html/custom_apps
      - /var/data/nextcloud/config:/var/www/html/config
      - /var/data/nextcloud/data:/var/www/html/data

  db:
    image: mariadb:10.5 #(1)!
    env_file: /var/data/config/nextcloud/nextcloud.env
    networks:
      - internal
    volumes:
      - /var/data/runtime/nextcloud/db:/var/lib/mysql

  db-backup:
    image: mariadb:10.5
    env_file: /var/data/config/nextcloud/nextcloud-backup.env
    volumes:
      - /var/data/nextcloud/database-dump:/dump
      - /etc/localtime:/etc/localtime:ro
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        mysqldump -h db --all-databases | gzip -c > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.sql.gz
        ls -tr /dump/dump_*.sql.gz | head -n -"$$BACKUP_NUM_KEEP" | xargs -r rm
        sleep $$BACKUP_FREQUENCY
      done
      EOF'
    networks:
      - internal

  redis:
    image: redis:alpine
    networks:
      - internal
    volumes:
      - /var/data/runtime/nextcloud/redis:/data

  cron:
    image: nextcloud
    volumes:
    - /var/data/nextcloud/html:/var/www/html
    - /var/data/nextcloud/apps:/var/www/html/custom_apps
    - /var/data/nextcloud/config:/var/www/html/config
    - /var/data/nextcloud/data:/var/www/html/data
    user: www-data
    networks:
      - internal
    entrypoint: |
      bash -c 'bash -s <<EOF
        trap "break;exit" SIGHUP SIGINT SIGTERM
        while [ ! -f /var/www/html/config/config.php ]; do
          sleep 1
        done
        while true; do
          php -f /var/www/html/cron.php
          sleep 15m
        done
      EOF'

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.12.0/24
```

1. MariaDB 10.5 is the latest supported version

--8<-- "reference-networks.md"

## Serving

### Launch NextCloud Docker stack and setup

Launch the NextCloud stack by running ```docker stack deploy nextcloud -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, and setup your admin username and password.

[^1]: Since many of my other recipes use PostgreSQL, I'd have preferred to use Postgres over MariaDB, but MariaDB seems to be the [preferred database type](https://github.com/nextcloud/server/issues/5912).
[^2]: If you want better performance when using Photos in Nextcloud, have a look at [this detailed write-up](https://rayagainstthemachine.net/linux%20administration/nextcloud-photos/)!

{% include 'recipe-footer.md' %}
