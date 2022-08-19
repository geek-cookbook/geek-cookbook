---
title: Install Mastodon in Docker Swarm
description: How to install your own Mastodon instance using Docker Swarm
---

# Install Mastodon in Docker Swarm

[Mastodon](https://joinmastodon.org/) is an open-source, federated (*i.e., decentralized*) social network, inspired by Twitter's "microblogging" format, and used by upwards of 4.4M early-adopters, to share links, pictures, video and text.

![Mastodon Screenshot](/images/mastodon.png){ loading=lazy }

!!! question "Why would I run my own instance?"
    That's a good question. After all, there are all sorts of public instances available, with a [range of themes and communities](https://joinmastodon.org/communities). You may want to run your own instance because you like the tech, because you just think it's cool :material-emoticon-cool-outline:

    You may also have realized that since Mastodon is **federated**, users on your instance can follow, toot, and interact with users on any other instance!

    If you're **not** into that much effort / pain, you're welcome to [join our instance][community/mastodon] :material-mastodon:

## Mastodon requirements

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/) (*Alternatively, see the [Kubernetes recipe here][k8s/mastodon]*)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your epic new social network, pointed to your [keepalived](/docker-swarm/keepalived/) IP
    * [ ] An S3-compatible bucket for serving media (*I use [Backblaze B2](https://www.backblaze.com/b2/docs/s3_compatible_api.html)*)
    * [ ] An SMTP gateway for delivering email notifications (*I use [Mailgun](https://www.mailgun.com/)*)
    * [ ] A business card, with the title "[*I'm CEO, Bitch*](https://nextshark.com/heres-the-story-behind-mark-zuckerbergs-im-ceo-bitch-business-card/)"

### Setup data locations

First, we create a directory to hold the Mastodon docker-compose configuration:

```bash
mkdir /var/data/config/mastodon
```

Then we setup directories to hold all the various data:

```bash
mkdir -p /var/data/runtime/mastodon/redis
mkdir -p /var/data/runtime/mastodon/elasticsearch
mkdir -p /var/data/runtime/mastodon/postgres 
```

!!! question "Why `/var/data/runtime/mastodon` and not just `/var/data/mastodon`?"
    The data won't be able to be backed up by a regular filesystem backup, because it'll be in use. We still need to store it **somewhere** though, so we use `/var/data/runtime`, which is excluded from automated backups. See [Data Layout](/reference/data_layout/) for details.

### Setup Mastodon enviroment

Create `/var/data/config/mastodon/mastodon.env` something like the example below..

```yaml title="/var/data/config/mastodon/mastodon.env"
# This is a sample configuration file. You can generate your configuration
# with the `rake mastodon:setup` interactive setup wizard, but to customize
# your setup even further, you'll need to edit it manually. This sample does
# not demonstrate all available configuration options. Please look at
# https://docs.joinmastodon.org/admin/config/ for the full documentation.

# Note that this file accepts slightly different syntax depending on whether
# you are using `docker-compose` or not. In particular, if you use
# `docker-compose`, the value of each declared variable will be taken verbatim,
# including surrounding quotes.
# See: https://github.com/mastodon/mastodon/issues/16895

# Federation
# ----------
# This identifies your server and cannot be changed safely later
# ----------
LOCAL_DOMAIN=example.com  # (1)!

# Redis
# -----
REDIS_HOST=redis
REDIS_PORT=6379

# PostgreSQL
# ----------
DB_HOST=db
DB_USER=postgres
DB_NAME=postgres
DB_PASS=tootmeupbuttercup # (2)!
DB_PORT=5432

# Elasticsearch (optional)
# ------------------------
ES_ENABLED=false  # (3)!
ES_HOST=es
ES_PORT=9200
# Authentication for ES (optional)
ES_USER=elastic
ES_PASS=password

# Secrets
# -------
# Make sure to use `rake secret` to generate secrets
# -------
SECRET_KEY_BASE=imafreaksecretbaby  # (4)!
OTP_SECRET=imtoosecretformysocks  

# Web Push
# --------
# Generate with `rake mastodon:webpush:generate_vapid_key`
# docker run -it tootsuite/mastodon bundle exec rake mastodon:webpush:generate_vapid_key
# --------
VAPID_PRIVATE_KEY=  # (5)!
VAPID_PUBLIC_KEY= 

# Sending mail # (6)!
# ------------
SMTP_SERVER=smtp.mailgun.org
SMTP_PORT=587
SMTP_LOGIN=
SMTP_PASSWORD=
SMTP_FROM_ADDRESS=notifications@example.com

# File storage (optional)  # (7)!
# -----------------------
S3_ENABLED=true
S3_BUCKET=files.example.com
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_ALIAS_HOST=files.example.com

# IP and session retention
# -----------------------
# Make sure to modify the scheduling of ip_cleanup_scheduler in config/sidekiq.yml
# to be less than daily if you lower IP_RETENTION_PERIOD below two days (172800).
# -----------------------
IP_RETENTION_PERIOD=31556952
SESSION_RETENTION_PERIOD=31556952
```

1. Set this to the FQDN you plan to use for your instance.
2. It doesn't matter what this is set to, since we're using `POSTGRES_HOST_AUTH_METHOD=trust`, but I've left it in for completeness and consistency with Mastodon's docs
3. Only enable this if you have enough resources for an Elasticsearch instance for full-text indexing
4. Generate these with `docker run -it tootsuite/mastodon bundle exec rake secret`
5. Generate these with `docker run -it tootsuite/mastodon bundle exec rake mastodon:webpush:generate_vapid_key`
6. You'll need to complete this if you want to send email
7. You'll need to complete this if you want to host media elsewhere

### Mastodon Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like this example:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/mastodon/mastodon.yml"
version: '3.5'
services:
  db:
    image: postgres:14-alpine
    networks:
      - internal
    healthcheck:
      test: ['CMD', 'pg_isready', '-U', 'postgres']
    volumes:
      - /var/data/runtime/mastodon/postgres:/var/lib/postgresql/data    
    environment:
      - 'POSTGRES_HOST_AUTH_METHOD=trust'

  redis:
    image: redis:6-alpine
    networks:
      - internal
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
    volumes:
      - /var/data/runtime/mastodon/redis:/data

  # es:
  #   image: docker.elastic.co/elasticsearch/elasticsearch:7.17.4
  #   environment:
  #     - "ES_JAVA_OPTS=-Xms512m -Xmx512m -Des.enforce.bootstrap.checks=true"
  #     - "xpack.license.self_generated.type=basic"
  #     - "xpack.security.enabled=false"
  #     - "xpack.watcher.enabled=false"
  #     - "xpack.graph.enabled=false"
  #     - "xpack.ml.enabled=false"
  #     - "bootstrap.memory_lock=true"
  #     - "cluster.name=es-mastodon"
  #     - "discovery.type=single-node"
  #     - "thread_pool.write.queue_size=1000"
  #   networks:
  #      - internal
  #   healthcheck:
  #      test: ["CMD-SHELL", "curl --silent --fail localhost:9200/_cluster/health || exit 1"]
  #   volumes:
  #      - /var/data/runtime/mastodon/elasticsearch:/usr/share/elasticsearch/data
  #   ulimits:
  #     memlock:
  #       soft: -1
  #       hard: -1
  #     nofile:
  #       soft: 65536
  #       hard: 65536
  #   ports:
  #     - '9200:9200'

  web:
    image: tootsuite/mastodon
    env_file: /var/data/config/mastodon/mastodon.env
    command: bash -c "rm -f /mastodon/tmp/pids/server.pid; bundle exec rails s -p 3000"
    networks:
      - internal
      - traefik_public
    healthcheck:
      test: ['CMD-SHELL', 'wget -q --spider --proxy=off localhost:3000/health || exit 1']
    volumes:
      - /var/data/mastodon:/mastodon/public/system
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv2
        - "traefik.http.routers.mastodon.rule=Host(`mastodon.example.com`)"
        - "traefik.http.routers.mastodon.entrypoints=https"
        - "traefik.http.services.mastodon.loadbalancer.server.port=3000"

  streaming:
    image: tootsuite/mastodon
    env_file: /var/data/config/mastodon/mastodon.env
    command: node ./streaming
    networks:
      - internal
      - traefik_public
    healthcheck:
      test: ['CMD-SHELL', 'wget -q --spider --proxy=off localhost:4000/api/v1/streaming/health || exit 1']
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv2
        - "traefik.http.routers.mastodon.rule=Host(`mastodon.example.com`) && PathPrefix(`/api/v1/streaming`))"
        - "traefik.http.routers.mastodon.entrypoints=https"
        - "traefik.http.services.mastodon.loadbalancer.server.port=3000"

  sidekiq:
    image: tootsuite/mastodon
    env_file: /var/data/config/mastodon/mastodon.env
    command: bundle exec sidekiq
    networks:
      - internal
    volumes:
      - /var/data/mastodon:/mastodon/public/system
    healthcheck:
      test: ['CMD-SHELL', "ps aux | grep '[s]idekiq\ 6' || false"]

  ## Uncomment to enable federation with tor instances along with adding the following ENV variables
  ## http_proxy=http://privoxy:8118
  ## ALLOW_ACCESS_TO_HIDDEN_SERVICE=true
  # tor:
  #   image: sirboops/tor
  #   networks:
  #      - internal
  #
  # privoxy:
  #   image: sirboops/privoxy
  #   volumes:
  #     - /var/data/mastodon/privoxy:/opt/config
  #   networks:
  #     - internal

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.9.0/24
```

--8<-- "reference-networks.md"

## Pre-warming

Unlike most recipes, we can't just deploy Mastodon into Docker Swarm, and trust it to setup its database itself. We have to "pre-warm" it using docker-compose, per the official docs (*Docker Swarm is not officially supported*)

### Start with docker-compose

From the `/var/data/config/mastodon` directory, run the following to start up the Mastodon environment using docker-compose. This will result in a **broken** environment, since the database isn't configured yet, but it provides us the opportunity to configure it.

```bash
docker-compose -f mastodon.yml up -d
```

The output should look something like this:

```bash
root@raphael:/var/data/config/mastodon# docker-compose -f mastodon.yml up -d
WARNING: Some services (streaming, web) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
WARNING: The Docker Engine you're using is running in swarm mode.

Compose does not use swarm mode to deploy services to multiple nodes in a swarm. All containers will be scheduled on the current node.

To deploy your application across the swarm, use `docker stack deploy`.

Creating mastodon_sidekiq_1   ... done
Creating mastodon_db_1        ... done
Creating mastodon_redis_1     ... done
Creating mastodon_streaming_1 ... done
Creating mastodon_web_1       ... done
root@raphael:/var/data/config/mastodon#
```

### Create database

Run the following to create the database. You can expect this to take a few minutes, and produce a **lot** of output:

```bash
cd /var/data/config/mastodon
docker-compose -f mastodon.yml run --rm web bundle exec rake db:migrate
```

### Create admin user

Next, decide on your chosen username, and create your admin user:

```bash
cd /var/data/config/mastodon
docker-compose -f mastodon.yml run --rm web bin/tootctl accounts \
create <username> --email <email address> --confirmed --role admin
```

The password will be output on completion[^1]:

```bash
root@raphael:/var/data/config/mastodon# docker-compose -f mastodon.yml run --rm web bin/tootctl accounts create batman --email batman@batcave.org --confirmed --role admin
WARNING: Some services (streaming, web) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
OK
New password: c6eb8e0d10cd6f0aa874b7a384177a08
root@raphael:/var/data/config/mastodon#
```

### Turn off docker-compose

We've setup the essestials now, everything else can be configured either via the UI or via the `.env` file, so tear down the docker-compose environment with:

```bash
docker-compose -f mastodon.yml down
```

The output should look like this:

```bash
root@raphael:/var/data/config/mastodon# docker-compose -f mastodon.yml down
WARNING: Some services (streaming, web) use the 'deploy' key, which will be ignored. Compose does not support 'deploy' configuration - use `docker stack deploy` to deploy to a swarm.
Stopping mastodon_streaming_1 ... done
Stopping mastodon_web_1       ... done
Stopping mastodon_db_1        ... done
Stopping mastodon_redis_1     ... done
Stopping mastodon_sidekiq_1   ... done
Removing mastodon_streaming_1 ... done
Removing mastodon_web_1       ... done
Removing mastodon_db_1        ... done
Removing mastodon_redis_1     ... done
Removing mastodon_sidekiq_1   ... done
Removing network mastodon_internal
Network traefik_public is external, skipping
root@raphael:/var/data/config/mastodon#
```

## :material-mastodon: Launch Mastodon!

Launch the Mastodon stack by running:

```bash
docker stack deploy mastodon -c /var/data/config/mastodon/mastodon.yml
```

Now hit the URL you defined in your config, and you should see your beautiful new Mastodon instance! Login with your configured credentials, navigate to **Preferences**, and have fun tweaking and tooting away!

Once you're done, "toot" me by mentioning [funkypenguin@so.fnky.nz](https://so.fnky.nz/@funkypenguin) in a toot! :wave:

!!! tip
    If your instance feels lonely, try using some [relays](https://github.com/brodi1/activitypub-relays) to bring in the federated firehose!

## Summary

What have we achieved? Even though we had to jump through some extra hoops to setup database and users, we now have a fully-swarmed Mastodon instance, ready to federate with the world! :material-mastodon:

!!! summary "Summary"
    Created:

    * [X] Mastodon configured, running, and ready to toot!

--8<-- "recipe-footer.md"

[^1]: Or, you can just reset your password from the UI, assuming you have SMTP working
