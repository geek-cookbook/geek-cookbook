hero: Gitlab - A recipe for a self-hosted GitHub alternative

# GitLab

GitLab is a self-hosted [alternative to GitHub](https://about.gitlab.com/comparison/). The most common use case is (a set of) developers with the desire for the rich feature-set of GitHub, but with unlimited private repositories.

Docker does maintain an [official "Omnibus" container](https://docs.gitlab.com/omnibus/docker/README.html), but for this recipe I prefer the "[dockerized gitlab](https://github.com/sameersbn/docker-gitlab)" project, since it allows distribution of the various Gitlab components across multiple swarm nodes.

--8<-- "recipe-standard-ingredients.md"

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
DB_PASS=gitlabdbpass
DB_NAME=gitlabhq_production
DB_EXTENSION=pg_trgm
DB_ADAPTER=postgresql
DB_HOST=postgresql
TZ=Pacific/Auckland
REDIS_HOST=redis
REDIS_PORT=6379
GITLAB_TIMEZONE=Auckland
GITLAB_HTTPS=true
SSL_SELF_SIGNED=false
GITLAB_HOST=gitlab.example.com
GITLAB_PORT=443
GITLAB_SSH_PORT=2222
GITLAB_SECRETS_DB_KEY_BASE=CFf7sS3kV2nGXBtMHDsTcjkRX8PWLlKTPJMc3lRc6GCzJDdVljZ85NkkzJ8mZbM5
GITLAB_SECRETS_SECRET_KEY_BASE=h2LBVffktDgb6BxM3B97mDSjhnSNwLc5VL2Hqzq9cdrvBtVw48WSp5wKj5HZrJM5
GITLAB_SECRETS_OTP_KEY_BASE=t9LPjnLzbkJ7Nt6LZJj6hptdpgG58MPJPwnMMMDdx27KSwLWHDrz9bMWXQMjq5mp
GITLAB_ROOT_PASSWORD=changeme
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
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
    env_file: /var/data/config/gitlab/gitlab.env
    volumes:
    - /var/data/gitlab/postgresql:/var/lib/postgresql:Z
    networks:
    - internal

  gitlab:
    image: sameersbn/gitlab:latest
    env_file: /var/data/config/gitlab/gitlab.env
    networks:
    - internal
    - traefik_public
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
    - "2222:22"
    volumes:
    - /var/data/gitlab/gitlab:/home/git/data:Z

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.2.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch gitlab

Launch the mail server stack by running ```docker stack deploy gitlab -c <path -to-docker-compose.yml>```

Log into your new instance at https://[your FQDN], with user "root" and the password you specified in gitlab.env.

[^1]: I use the **sameersbn/gitlab:latest** image, rather than a specific version. This lets me execute updates simply by redeploying the stack (and why **wouldn't** I want the latest version?)

--8<-- "recipe-footer.md"