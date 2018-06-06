# Tiny Tiny RSS

[Tiny Tiny RSS](https://tt-rss.org/) is a self-hosted, AJAX-based RSS reader, which rose to popularity as a replacement for Google Reader. It supports ~~geeky~~ advanced features, such as:

* Plugins and themeing in a drop-in fashion
* Filtering (discard all articles with title matching "trump")
* Sharing articles via a unique public URL/feed

![Tiny Tiny RSS Screenshot](../images/tiny-tiny-rss.png)

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/ttrss:

```
mkdir /var/data/ttrss
cd /var/data/ttrss
mkdir -p {database,database-dump}
```

### Prepare environment

Create ttrss.env, and populate with the following variables, customizing at least the database password (POSTGRES_PASSWORD **and** DB_PASS) and the TTRSS_SELF_URL to point to your installation.

```
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

### Setup docker swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:
    db:
      image: postgres:latest
      env_file: /var/data/ttrss/ttrss.env
      volumes:
        - /var/data/ttrss/database:/var/lib/postgresql/data
      networks:
        - internal

    app:
      image: funkypenguin/docker-ttrss
      env_file: /var/data/ttrss/ttrss.env
      deploy:
        labels:
          - traefik.frontend.rule=Host:ttrss.funkypenguin.co.nz
          - traefik.docker.network=traefik
          - traefik.port=8080
      networks:
        - internal
        - traefik

    db-backup:
      image: postgres:latest
      env_file: /var/data/ttrss/ttrss.env
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
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.5.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.


## Serving

### Launch TTRSS stack

Launch the TTRSS stack by running ```docker stack deploy ttrss -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN** - the first user you create will be an administrative user.


## Chef's Notes

There are several TTRSS containers available on docker hub, none of them "official". I chose [x86dev's container](https://github.com/x86dev/docker-ttrss) for its features - such as my favorite skins and plugins, and the daily automatic updates from the "rolling release" master. Some of the features of the container I use are due to a [PR](https://github.com/x86dev/docker-ttrss/pull/12) I submitted:

1. Docker swarm looses the docker-compose concept of "dependencies" between containers. In the case of this stack, the application server typically starts up before the database container, which causes the database autoconfiguration scripts to fail, and brings up the app in a broken state. To prevent this, I  include "[wait-for](https://github.com/Eficode/wait-for/)", which (combined with "S6_BEHAVIOUR_IF_STAGE2_FAILS=2"), will cause the app container to restart (and attempt to auto-configure itself) until the database is ready.

2. The upstream git URL [changed recently](https://discourse.tt-rss.org/t/gitlab-is-overbloated-shit-garbage/325/6), but my experience of the new repository is that it's **SO** slow, that the initial "git clone" on setup of the container times out. To work around this, I created [my own repo](https://github.com/funkypenguin/tt-rss.git), cloned upstream, pushed it into my repo, and pointed the container at my own repo with TTRSS_REPO. I don't get the _latest_ code changes, but at least the app container starts up. When upstream git is performing properly, I'll remove TTRSS_REPO to revert back to the "rolling release".

### Tip your waiter (donate) 

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 

### Your comments? 
