hero: Gitlab - A recipe for a self-hosted GitHub alternative

# GitLab

GitLab is a self-hosted [alternative to GitHub](https://about.gitlab.com/comparison/). The most common use case is (a set of) developers with the desire for the rich feature-set of GitHub, but with unlimited private repositories.

Docker does maintain an [official "Omnibus" container](https://docs.gitlab.com/omnibus/docker/README.html), but for this recipe I prefer the "[dockerized gitlab](https://github.com/sameersbn/docker-gitlab)" project, since it allows distribution of the various Gitlab components across multiple swarm nodes.

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/gitlab:

```
cd /var/data
mkdir gitlab
cd gitlab
mkdir -p {postgresql,redis,gitlab}
```

### Prepare environment

You'll need to know the following:

1. Choose a password for postgresql, you'll need it for DB_PASS in the compose file (below)
2. Generate 3 passwords using ```pwgen -Bsv1 64```. You'll use these for the XXX_KEY_BASE environment variables below
2. Create gitlab.env, and populate with **at least** the following variables (the full set is available at https://github.com/sameersbn/docker-gitlab#available-configuration-parameters):
```
DB_USER=gitlab
DB_PASS=<as determined above>
TZ=Pacific/Auckland
GITLAB_TIMEZONE=Auckland
GITLAB_HTTPS=true
SSL_SELF_SIGNED=false
GITLAB_HOST
GITLAB_PORT
GITLAB_SSH_PORT
GITLAB_SECRETS_DB_KEY_BASE
GITLAB_SECRETS_SECRET_KEY_BASE
GITLAB_SECRETS_OTP_KEY_BASE
GITLAB_ROOT_PASSWORD
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

````
version: '3'

services:
  redis:
    image: sameersbn/redis:latest
    command:
    - --loglevel warning
    volumes:
    - /var/data/gitlab/redis:/var/lib/redis:Z
    networks:
    - internal

  postgresql:
    image: sameersbn/postgresql:9.6-2
    volumes:
    - /var/data/gitlab/postgresql:/var/lib/postgresql:Z
    networks:
    - internal
    environment:
    - DB_USER=gitlab
    - DB_PASS=<your db password>
    - DB_NAME=gitlabhq_production
    - DB_EXTENSION=pg_trgm

  gitlab:
    image: sameersbn/gitlab:latest
    networks:
    - internal
    - traefik
    deploy:
      labels:
        - traefik.frontend.rule=Host:gitlab.example.com
        - traefik.docker.network=traefik
        - traefik.port=80
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
    ports:
    - "10022:22"
    volumes:
    - /var/data/gitlab/gitlab:/home/git/data:Z
    env_file: gitlab.env

networks:
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.2.0/24
````

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.







## Serving

### Launch gitlab

Launch the mail server stack by running ```docker stack deploy gitlab -c <path -to-docker-compose.yml>```

Log into your new instance at https://[your FQDN], with user "root" and the password you specified in gitlab.env.


## Chef's Notes

A few comments on decisions taken in this design:

1. I use the **sameersbn/gitlab:latest** image, rather than a specific version. This lets me execute updates simply by redeploying the stack (and why **wouldn't** I want the latest version?)


## Your comments?
