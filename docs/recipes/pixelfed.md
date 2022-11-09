---
title: How I run Pixelfed in Docker Swarm
description: How to install your own Pixelfed instance using Docker Swarm
status: new
---

# Pixelfed in Docker Swarm

[Pixelfed](https://pixelfed.org) is a free and ethical, open-source, federated (*i.e., decentralized*) social image sharing platform. As [Mastodon][mastodon] is to Twitter, so Pixelfed is to Instagram. Pixelfed uses the ActivityPub protocol, allowing users to interact with other users (*on other servers*) within the protocol, such as Mastodon, PeerTube, and Friendica, making Pixelfed a part of the Fediverse.

Much like Mastodon, Pixelfed implements chronological timelines with no implementation of content manipulation algorithms and is privacy-focused with no third party analytics or tracking. It only allows users over 16 years old to use.

![Pixelfed Screenshot](/images/pixelfed.png){ loading=lazy }

!!! question "Why would I run my own instance?"
    That's a good question. After all, there are [all sorts](https://pixelfed.fediverse.observer/list) of [public instances](https://the-federation.info/pixelfed) available, with a [range of themes and communities](https://fedidb.org/software/pixelfed). You may want to run your own instance because you like the tech, because you just think it's cool :material-emoticon-cool-outline:

    You may also have realized that since Pixelfed is **federated**, users on your instance can follow, comment, and interact with users on any other instance!

!!! note
    Pixelfed's [docs](https://docs.pixelfed.org/running-pixelfed/installation/) point out that:

    > Pixelfed is still a work in progress. We do not recommending running an instance in production at this stage unless you know what you are doing!

    
    Having said this, there are[ 271 known instances with over 100,000 users](https://fedidb.org/software/pixelfed), some of which have been operational for over 2 years. [pixelfed.de](https://pixelfed.de) is one such instance, and the images and docker-compose configuration used in this recipe were originally found in a [2020 blog post](https://blog.pixelfed.de/2020/05/29/pixelfed-in-docker/).

## Pixelfed requirements

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your epic new image platform, pointed to your [keepalived](/docker-swarm/keepalived/) IP
    * [ ] Optionally (*but recommended*), an S3-compatible bucket for caching/serving media (*I use [Backblaze B2](https://www.backblaze.com/b2/docs/s3_compatible_api.html)*)
    * [ ] An SMTP gateway for delivering email notifications (*I use [Mailgun](https://www.mailgun.com/)*)

### Setup data locations

First, we create a directory to hold the Pixelfed docker-compose configuration:

```bash
mkdir /var/data/config/pixelfed
```

Then we setup directories to hold all the various data:

```bash
mkdir -p /var/data/runtime/pixelfed/redis
mkdir -p /var/data/runtime/pixelfed/mariadb 
mkdir -p /var/data/pixelfed/
chown www-data /var/data/pixelfed/
```

!!! question "Why `/var/data/runtime/pixelfed` and not just `/var/data/pixelfed`?"
    The data won't be able to be backed up by a regular filesystem backup, because it'll be in use. We still need to store it **somewhere** though, so we use `/var/data/runtime`, which is excluded from automated backups. See [Data Layout](/reference/data_layout/) for details.

### Setup Pixelfed environment

Create `/var/data/config/pixelfed/pixelfed.env` something like the example below.. (*see the [official documentation](https://docs.pixelfed.org/technical-documentation/config/) for a list of all possible variables and details*)

```yaml title="/var/data/config/pixelfed/pixelfed.env"
## Crypto
APP_KEY=

## General Settings
APP_NAME="Pixelfed Prod"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://pixelfed.example.com
APP_DOMAIN="pixelfed.example.com"
ADMIN_DOMAIN="pixelfed.example.com"
SESSION_DOMAIN="pixelfed.example.com"

OPEN_REGISTRATION=true
ENFORCE_EMAIL_VERIFICATION=false
PF_MAX_USERS=1000
OAUTH_ENABLED=true

APP_TIMEZONE=UTC
APP_LOCALE=en

## Pixelfed Tweaks
LIMIT_ACCOUNT_SIZE=true
MAX_ACCOUNT_SIZE=1000000
MAX_PHOTO_SIZE=15000
MAX_AVATAR_SIZE=2000
MAX_CAPTION_LENGTH=500
MAX_BIO_LENGTH=125
MAX_NAME_LENGTH=30
MAX_ALBUM_LENGTH=4
IMAGE_QUALITY=80
PF_OPTIMIZE_IMAGES=true
PF_OPTIMIZE_VIDEOS=true
ADMIN_ENV_EDITOR=false
ACCOUNT_DELETION=true
ACCOUNT_DELETE_AFTER=false
MAX_LINKS_PER_POST=0

## Instance
#INSTANCE_DESCRIPTION=
INSTANCE_PUBLIC_HASHTAGS=false
#INSTANCE_CONTACT_EMAIL=
INSTANCE_PUBLIC_LOCAL_TIMELINE=false
#BANNED_USERNAMES=
STORIES_ENABLED=false
RESTRICTED_INSTANCE=false

## Mail
MAIL_DRIVER=log
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_FROM_ADDRESS=pixelfed@example.com
MAIL_FROM_NAME="Pixelfed"
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

## Databases (MySQL)
DB_CONNECTION=mysql
DB_DATABASE=pixelfed_prod
DB_HOST=db
DB_PASSWORD=pixelfed_db_pass
DB_PORT=3306
DB_USERNAME=pixelfed
# pass the same values to the db itself
MYSQL_DATABASE=pixelfed_prod
MYSQL_PASSWORD=pixelfed_db_pass
MYSQL_RANDOM_ROOT_PASSWORD=true
MYSQL_USER=pixelfed

## Databases (Postgres)
#DB_CONNECTION=pgsql
#DB_HOST=postgres
#DB_PORT=5432
#DB_DATABASE=pixelfed
#DB_USERNAME=postgres
#DB_PASSWORD=postgres

## Cache (Redis)
REDIS_CLIENT=phpredis
REDIS_SCHEME=tcp
REDIS_HOST=redis
#REDIS_PASSWORD=redis_password
REDIS_PORT=6379
REDIS_DATABASE=0

HORIZON_PREFIX="horizon-"

## EXPERIMENTS 
EXP_LC=false
EXP_REC=false
EXP_LOOPS=false

## ActivityPub Federation
ACTIVITY_PUB=false
AP_REMOTE_FOLLOW=false
AP_SHAREDINBOX=false
AP_INBOX=false
AP_OUTBOX=false
ATOM_FEEDS=true
NODEINFO=true
WEBFINGER=true

## S3
FILESYSTEM_DRIVER=local
FILESYSTEM_CLOUD=s3
PF_ENABLE_CLOUD=false
#AWS_ACCESS_KEY_ID=
#AWS_SECRET_ACCESS_KEY=
#AWS_DEFAULT_REGION=
#AWS_BUCKET=
#AWS_URL=
#AWS_ENDPOINT=
#AWS_USE_PATH_STYLE_ENDPOINT=false

## Horizon
HORIZON_DARKMODE=false

## COSTAR - Confirm Object Sentiment Transform and Reduce
PF_COSTAR_ENABLED=false

# Media
MEDIA_EXIF_DATABASE=false

## Logging
LOG_CHANNEL=stderr

## Image
IMAGE_DRIVER=imagick

## Broadcasting
# log driver for local development
BROADCAST_DRIVER=log

## Cache
CACHE_DRIVER=redis

## Purify
RESTRICT_HTML_TYPES=true

## Queue
QUEUE_DRIVER=redis

## Session
SESSION_DRIVER=redis

## Trusted Proxy
TRUST_PROXIES="*"

## Passport
#PASSPORT_PRIVATE_KEY=
#PASSPORT_PUBLIC_KEY=
```

Having created `pixelfed.env`, set it to be owned by `www-data`, since the subsequent steps run by the app container will modify it, inserting the `APP_KEY`:

```bash
chown www-data /var/data/config/pixelfed/pixelfed.env
```

### Pixelfed Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like this example:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/pixelfed/pixelfed.yml"
version: '3.5'
services:
  db:
    image: mariadb
    restart: unless-stopped # makes running maintenance jobs using docker-compose more reliable
    env_file: /var/data/config/pixelfed/pixelfed.env
    networks:
      - internal
    volumes:
      - /var/data/runtime/pixelfed/mariadb:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=yeschangemeforproduction

  redis:
    image: zknt/redis
    restart: unless-stopped # makes running maintenance jobs using docker-compose more reliable
    networks:
      - internal
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
    volumes:
      - /var/data/runtime/pixelfed/redis:/data

  worker:
    image: zknt/pixelfed
    restart: unless-stopped # makes running maintenance jobs using docker-compose more reliable
    env_file: /var/data/config/pixelfed/pixelfed.env
    entrypoint: /worker-entrypoint.sh
    networks:
      - internal
    healthcheck:
      test: ['CMD', 'php artisan horizon:status | grep running']
    volumes:
      - /var/data/pixelfed:/var/www/storage
      - /var/data/config/pixelfed/pixelfed.env:/var/www/.env

  app:
    image: zknt/pixelfed
    restart: unless-stopped # makes running maintenance jobs using docker-compose more reliable
    env_file: /var/data/config/pixelfed/pixelfed.env
    networks:
      - internal
      - traefik_public
    volumes:
      - /var/data/pixelfed:/var/www/storage
      - /var/data/config/pixelfed/pixelfed.env:/var/www/.env
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv2
        - "traefik.http.routers.pixelfed.rule=Host(`pixelfed.example.com`)"
        - "traefik.http.routers.pixelfed.entrypoints=https"
        - "traefik.http.services.pixelfed.loadbalancer.server.port=80"

  # maintenance:
  #   image: zknt/pixelfed
  #   restart: unless-stopped # makes running maintenance jobs using docker-compose more reliable
  #   env_file: /var/data/config/pixelfed/pixelfed.env
  #   entrypoint: /worker-entrypoint.sh
  #   networks:
  #     - internal
  #   healthcheck:
  #     test: ['CMD', 'php artisan horizon:status | grep running']
  #   volumes:
  #     - /var/data/pixelfed:/var/www/storage
  #     - /var/data/config/pixelfed/pixelfed.env:/var/www/.env

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.17.0/2
```

--8<-- "reference-networks.md"

## Pre-warming

Unlike most recipes, we can't just deploy Pixelfed into Docker Swarm, and trust it to setup its database and users itself. We have to "pre-warm" it using docker-compose...

### Start with docker-compose

From the `/var/data/config/pixelfed` directory, run the following to start up the Pixelfed environment using docker-compose. This will trigger all the initial database seeding / migration jobs, but all the containers will run on the same host (*not in the swarm*), so that we can perform additional admin tasks.

```bash
cd /var/data/config/pixelfed
docker-compose -f pixelfed.yml up -d # (1)!
docker-compose -f pixelfed.yml logs -f # (2)!
```

1. Start up in "detached" mode
2. Attach to the logs so that we can confirm readiness

You'll see the logs from each of the containers scroll by, and you'll note some warnings / errors displayed before the database is ready. When you see Apache start (*as below*), then you know it's ready:

```text
app_1     | ++ export APACHE_LOG_DIR=/var/log/apache2
app_1     | ++ APACHE_LOG_DIR=/var/log/apache2
app_1     | ++ export LANG=C
app_1     | ++ LANG=C
app_1     | ++ export LANG
app_1     | + /usr/local/sbin/dumb-init apache2 -DFOREGROUND
app_1     | AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.16.17.43. Set the 'ServerName' directive globally to suppress this message
```

Hit `CTRL-C` to stop the logs (*but not the containers*), and proceed to creating your admin user...

### Create admin user

Confirm the containers are running, with:

```bash
docker-compose -f pixelfed.yml ps
```

You'll want to see them all up and healthy, as illustrated below:

```bash
root@raphael:/var/data/config/pixelfed# docker-compose -f pixelfed.yml ps
WARNING: Some services (app) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
      Name                     Command                       State            Ports
-------------------------------------------------------------------------------------
pixelfed_app_1      /bin/sh -c /entrypoint.sh        Up                      80/tcp
pixelfed_db_1       docker-entrypoint.sh mariadbd    Up                      3306/tcp
pixelfed_redis_1    /bin/sh -c redis-server /e ...   Up (healthy)            6379/tcp
pixelfed_worker_1   /worker-entrypoint.sh            Up (health: starting)   80/tcp
root@raphael:/var/data/config/pixelfed#
```

Next, decide on your chosen username, and create your admin user, by running:

```bash
docker-compose -f pixelfed.yml exec app php artisan user:create
```

For example:

```bash
root@raphael:/var/data/config/pixelfed# docker-compose -f pixelfed.yml exec app php artisan user:create
WARNING: Some services (app) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
Creating a new user...

 Name:
 > David Young

 Username:
 > funkypenguin

 Email:
 > davidy@funkypenguin.co.nz

 Password:
 >

 Confirm Password:
 >

 Make this user an admin? (yes/no) [no]:
 > yes

 Manually verify email address? (yes/no) [no]:
 > yes

 Are you sure you want to create this user? (yes/no) [no]:
 > yes

Created new user!
root@raphael:/var/data/config/pixelfed#
```

### Import cities (optional)

I'm not sure exactly what this does - I think it lets you tag photos with individual cities, but it seemed worth doing :)

```bash
docker-compose -f pixelfed.yml exec app php artisan import:cities
```

Result:

```bash
root@raphael:/var/data/config/pixelfed# docker-compose -f pixelfed.yml exec app php artisan import:cities
WARNING: Some services (app) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
Importing city data into database ...

Found 128769 cities to insert ...

 128769/128769 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

Successfully imported 128769 entries!

root@raphael:/var/data/config/pixelfed#
```

### Turn off docker-compose

We've setup the essestials now, everything else can be configured either via the UI or via the `.env` file, so tear down the docker-compose environment with:

```bash
docker-compose -f pixelfed.yml down
```

The output should look like this:

```bash
root@raphael:/var/data/config/pixelfed# docker-compose -f pixelfed.yml down
WARNING: Some services (app) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
Removing pixelfed_worker_1 ... done
Removing pixelfed_db_1     ... done
Removing pixelfed_redis_1  ... done
Removing pixelfed_app_1    ... done
Removing network pixelfed_internal
Network traefik_public is external, skipping
root@raphael:/var/data/config/pixelfed#
```

## :material-camera-iris: Launch pixelfed!

Launch the pixelfed stack by running:

```bash
docker stack deploy pixelfed -c /var/data/config/pixelfed/pixelfed.yml
```

Now hit the URL you defined in your config, and you should see your beautiful new pixelfed instance! Login with the credentials you just setup, and have fun tweaking and snapping some selfies! [^1]

## Summary

What have we achieved? Even though we had to jump through some extra hoops to setup database and users, we now have a fully-swarmed Pixelfed instance, ready to federate with the world! :material-camera-iris:

!!! summary "Summary"
    Created:

    * [X] Pixelfed configured, running, and ready for selfies!

--8<-- "recipe-footer.md"

[^1]: There's an iOS mobile app [currently in beta](https://testflight.apple.com/join/5HpHJD5l)
