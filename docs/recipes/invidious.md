---
title: Invidious, your Youtube frontend instance in Docker Swarm
description: How to create your own private Youtube frontend using Invidious in Docker Swarm
status: new
---

# Invidious: Private Youtube frontend instance in Docker Swarm

YouTube is ubiquitious now. Almost every video I'm sent, takes me to YouTube. Worse, every YouTube video I watch feeds Google's profile about me, so shortly after enjoying the latest Marvel movie trailers, I find myself seeing related adverts on **unrelated** websites.

Creepy :bug:!

As the connection between the videos I watch and the adverts I see has become move obvious, I've become more discerning re which videos I choose to watch, since I don't necessarily **want** algorithmically-related videos popping up next time I load the YouTube app on my TV, or Marvel merchandise advertised to me on every second news site I visit.

This is a PITA since it means I have to "self-censor" which links I'll even click on, knowing that once I _do_ click the video link, it's forever associated with my Google account :facepalm:

After playing around with [some of the available public instances](https://docs.invidious.io/instances/) for a while, today I finally deployed my own instance of [Invidious](https://invidious.io/) - an open source alternative front-end to YouTube.

![Invidious Screenshot](/images/invidious.png){ loading=lazy }

Here's an example from my public instance:

<iframe id='ivplayer' width='640' height='360' src='https://in.fnky.nz/embed/o-YBDTqX_ZU?t=3' style='border:none;'></iframe>

## Invidious requirements

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your Invidious instance, pointed to your [keepalived](/docker-swarm/keepalived/) IP

### Setup data locations

First, we create a directory to hold the invidious docker-compose configuration:

```bash
mkdir /var/data/config/invidious
```

Then we setup directories to hold all the various data:

```bash
mkdir -p /var/data/invidious/database-dump
mkdir -p /var/data/runtime/invidious/database
```

### Setup Invidious environment

Create `/var/data/config/invidious/invidious.env` something like the example below..

```yaml title="/var/data/config/invidious/invidious.env"
POSTGRES_DB=invidious
POSTGRES_USER=invidious
POSTGRES_PASSWORD=youtubesucks
```

Then create `/var/data/config/invidious/invidious-db-backup.env`, like this:

```yaml title="/var/data/config/invidious/invidious-db-backup.env"
# For pg_dump running in postgres container (used for db-backup)
PGHOST=db
PGUSER=invidious
PGPASSWORD=youtubesucks
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```

### Invidious Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like this example[^1]:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/invidious/invidious.yml"
version: "3.2"

services:
  invidious:
    image: quay.io/invidious/invidious:latest
    environment:
      INVIDIOUS_CONFIG: |
        db: # make sure these values align with the indivious.env file you created
          dbname: invidious
          user: invidious
          password: youtubesucks
          host: db
          port: 5432
        check_tables: true
        external_port: 443
        domain: invidious.example.com # update this for your own domain
        https_only: true # because we use Traefik, all access is HTTPS
        # statistics_enabled: false   
        default_user_preferences:
          quality: dash # auto-adapts or lets you choose > 720P 
    env_file: /var/data/config/invidious/invidious.env
    deploy:
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"
        - "traefik.http.routers.invidious.rule=Host(`invidious.example.com`)"
        - "traefik.http.routers.invidious.entrypoints=https"
        - "traefik.http.services.invidious.loadbalancer.server.port=3000"        
    networks:
      - internal
      - traefik_public

  db:
    image: postgres:14
    env_file: /var/data/config/invidious/invidious.env
    volumes:
      - /var/data/runtime/invidious/database:/var/lib/postgresql/data
    networks:
      - internal

  db-backup:
    image: postgres:14
    env_file: /var/data/config/invidious/invidious-db-backup.env
    volumes:
      - /var/data/invidious/database-dump:/dump
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

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.21.0/24
```

--8<-- "reference-networks.md"

## Launch Invidious!

Launch the Invidious stack by running

```bash
docker stack deploy invidious -c /var/data/config/invidious/invidious.yml
```

Now hit the URL you defined in your config, you'll see the basic search screen. Enter a search phrase (*"marvel movie trailer"*) to see the YouTube video results, or paste in a YouTube URL such as `https://www.youtube.com/watch?v=bxqLsrlakK8`, change the domain name from `www.youtube.com` to your instance's FQDN, and watch the fun [^2]!

You can also install a range of browser add-ons to automatically redirect you from youtube.com to your Invidious instance. I'm testing "[libredirect](https://addons.mozilla.org/en-US/firefox/addon/libredirect/)" currently, which seems to work as advertised!

## Summary

What have we achieved? We have an HTTPS-protected private YouTube frontend - we can now watch whatever videos we please, without feeding Google's profile on us. We can also subscribe to channels without requiring a Google account, and we can share individual videos directly via our instance (*by generating links*).

!!! summary "Summary"
    Created:

    * [X] We are free of the creepy tracking attached to YouTube videos!

--8<-- "recipe-footer.md"

[^1]: Check out the [official config docs](https://github.com/iv-org/invidious/blob/master/config/config.example.yml) for comprehensive details on how to configure / tweak your instance!
[^2]: Gotcha!
