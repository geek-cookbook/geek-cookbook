hero: Duplicati - Yet another option to backup your exciting stuff. It's good to have options.

# Duplicati

Intro

![duplicati Screenshot](../images/duplicati.jpg)


[Duplicati](https://www.duplicati.com/) is a free and open-source backup software to store encrypted backups online For Windows, macOS and Linux (our favorite, yay!).

Similar to the other backup solution options in the Cookbook, you can use Duplicati to backup all our data-at-rest to a wide variety of locations, including, but not limited to:

- FTP servers
- SSH servers
- WebDAV endpoints
- Backblaze B2
- Tardigrade
- Microsoft OneDrive
- Amazon S3
- Google Drive
- box.com
- Mega
- hubiC
- many others

!!! note
    Since Duplicati itself offers no user authentication, this design secures Duplicati behind a [Traefik Forward Auth proxy](/ha-docker-swarm/traefik-forward-auth), so that in order to gain access to the Duplicati UI at all, oauth2 authentication (_to GitHub, GitLab, Google, etc_) must have already occurred.

## Ingredients

1. [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [X] [Traefik](/ha-docker-swarm/traefik_public) and [Traefik-Forward-Auth](/ha-docker-swarm/traefik-forward-auth) configured per design
3. Credentials for one of the Duplicati's supported upload destinations

## Preparation

### Setup data locations

We'll need a folder to store a docker-compose .yml file, and an associated .env file. If you're following my filesystem layout, create `/var/data/config/duplicati` (*for the config*), and `/var/data/duplicati` (*for the metadata*) as follows:

```
mkdir /var/data/config/duplicati
mkdir /var/data/duplicati
cd /var/data/config/duplicati
```

### Prepare environment

1. Generate a random passphrase to use to encrypt your data. **Save this somewhere safe**, without it you won't be able to restore!
2. Seriously, **save**. **it**. **somewhere**. **safe**.
3. Create duplicati.env, and populate with the following variables (with your appropriate time zone)
```
PUID=0
PGID=0
TZ=Europe/London
CLI_ARGS= #optional
```

!!! note
    By default, we're running Duplicati as the `root` user of the host system. This is because we need Duplicati to be able to read files of all the other services no matter which user that service is running as. Duplicati can't backup your exciting stuff if it can't read the files.


### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [sponsors](https://github.com/sponsors/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that sponsors can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

```
version: "3"
services:
  duplicati:
    image: linuxserver/duplicati
    env_file: /var/data/config/duplicati/duplicati.env
    deploy:
      replicas: 1
      labels:
        - traefik.enable=true
        - traefik.frontend.rule=Host:duplicati.example.com
        - traefik.port=8200
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true
        - traefik.docker.network=traefik_public
    volumes:
      - /var/data/config/duplicati:/config
      - /var/data:/source
    ports:
      - 8200:8200
    networks:
      - traefik_public
      - internal

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.55.0/24
```
!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.

## Serving

### Launch Duplicati stack

Launch the Duplicati stack by running ```docker stack deploy duplicati -c <path-to-docker-compose.yml>```

Authenticate against your OAuth provider, and then start configuring your backup jobs via the Duplicati UI!