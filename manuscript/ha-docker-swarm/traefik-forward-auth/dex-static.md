---
title: Using dex for simple, static authentication with traefik-forward-auth
description: Traefik-forward-auth needs an authentication backend, but if you don't want to use a cloud provider (like Google), you can setup your own simple backend, using Dex
---
# Using Traefik Forward Auth with Dex (Static)

[Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/) is incredibly useful to secure services with an additional layer of authentication, provided by an OIDC-compatible provider. The simplest possible provider is a self-hosted instance of [CoreOS's Dex](https://github.com/dexidp/dex), configured with a static username and password. This recipe will "get you started" with Traefik Forward Auth, providing a basic authentication layer. In time, you might want to migrate to a "public" provider, like [Google][tfa-google], or GitHub, or to a [KeyCloak][keycloak] installation.

--8<-- "recipe-tfa-ingredients.md"

## Preparation

### Setup dex config

Create `/var/data/config/dex/config.yml` something like the following (*this is a bare-bones, [minimal example](https://github.com/dexidp/dex/blob/master/config.dev.yaml)*). At the very least, you want to replace all occurances of `example.com` with your own domain name. (*If you change nothing else, your ID is `foo`, your secret is `bar`, your username is `admin@yourdomain`, and your password is `password`*):

```yaml
# The base path of dex and the external name of the OpenID Connect service.
#
# This is the canonical URL that all clients MUST use to refer to dex. If a
# path is provided, dex's HTTP service will listen at a non-root URL.
issuer: https://dex.example.com

storage:
  type: sqlite3
  config:
    file: var/sqlite/dex.db

web:
  http: 0.0.0.0:5556

oauth2:
  skipApprovalScreen: true

staticClients:
- id: foo
  redirectURIs:
  - 'https://auth.example.com/_oauth'
  name: 'example.com'
  secret: bar

enablePasswordDB: true

staticPasswords:
- email: "admin@example.com"
  # bcrypt hash of the string "password"
  hash: "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
  username: "admin"
  userID: "08a8684b-db88-4b73-90a9-3cd1661f5466"
```

### Prepare Traefik Forward Auth environment

Create `/var/data/config/traefik-forward-auth/traefik-forward-auth.env` per the following example configuration:

```bash
DEFAULT_PROVIDER: oidc
PROVIDERS_OIDC_CLIENT_ID: foo                         # This is the staticClients.id value in config.yml above
PROVIDERS_OIDC_CLIENT_SECRET: bar                     # This is the staticClients.secret value in config.yml above
PROVIDERS_OIDC_ISSUER_URL: https://dex.example.com    # This is the issuer value in config.yml above, and it has to be reachable via a browser
SECRET: imtoosexyformyshorts                          # Make this up. It's not configured anywhere else
AUTH_HOST: auth.example.com                           # This should match the value of the traefik hosts labels in Traefik Forward Auth
COOKIE_DOMAIN: example.com                            # This should match your base domain
```

### Setup Docker Stack for Dex

Now create a docker swarm config file in docker-compose syntax (v3), per the following example:

```yaml
version: '3'

services:
  dex:
    image: dexidp/dex
    volumes:
      - /etc/localtime:/etc/localtime:ro    
      - /var/data/config/dex/config.yml:/config.yml:ro
    networks:
      - traefik_public
    command: ['serve','/config.yml']
    deploy:
      labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:dex.example.com
      - traefik.port=5556
      - traefik.docker.network=traefik_public

      # and for traefikv2:
      - "traefik.http.routers.dex.rule=Host(`dex.example.com`)"
      - "traefik.http.routers.dex.entrypoints=https"
      - "traefik.http.services.dex.loadbalancer.server.port=5556"  
       
networks:
  traefik_public:
    external: true
```

--8<-- "premix-cta.md"

### Setup Docker Stack for Traefik Forward Auth

Now create a docker swarm config file for traefik-forward-auth, in docker-compose syntax (v3), per the following example:

```yaml
version: "3.2"

services:

  traefik-forward-auth:
    image: thomseddon/traefik-forward-auth:2.2.0
    env_file: /var/data/config/traefik-forward-auth/traefik-forward-auth.env
    volumes:
    - /var/data/config/traefik-forward-auth/config.ini:/config.ini:ro
    networks:
      - traefik_public
    deploy:
      labels:
        # traefikv1
        - "traefik.port=4181"
        - "traefik.frontend.rule=Host:auth.example.com"
        - "traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181"
        - "traefik.frontend.auth.forward.trustForwardHeader=true"

        # traefikv2
        - "traefik.docker.network=traefik_public"
        - "traefik.http.routers.auth.rule=Host(`auth.example.com`)"
        - "traefik.http.routers.auth.entrypoints=https"
        - "traefik.http.routers.auth.tls=true"
        - "traefik.http.routers.auth.tls.domains[0].main=example.com"
        - "traefik.http.routers.auth.tls.domains[0].sans=*.example.com"        
        - "traefik.http.routers.auth.tls.certresolver=main"
        - "traefik.http.routers.auth.service=auth@docker"
        - "traefik.http.services.auth.loadbalancer.server.port=4181"
        - "traefik.http.middlewares.forward-auth.forwardauth.address=http://traefik-forward-auth:4181"
        - "traefik.http.middlewares.forward-auth.forwardauth.trustForwardHeader=true"
        - "traefik.http.middlewares.forward-auth.forwardauth.authResponseHeaders=X-Forwarded-User"
        - "traefik.http.routers.auth.middlewares=forward-auth"

  # This simply validates that traefik forward authentication is working
  whoami:
    image: containous/whoami
    networks:
      - traefik_public
    deploy:
      labels:
        # traefik
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"

        # traefikv1
        - "traefik.frontend.rule=Host:whoami.example.com"
        - "traefik.http.services.whoami.loadbalancer.server.port=80"
        - "traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181"
        - "traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User"
        - "traefik.frontend.auth.forward.trustForwardHeader=true"

        # traefikv2
        - "traefik.http.routers.whoami.rule=Host(`whoami.example.com`)"
        - "traefik.http.routers.whoami.entrypoints=https"
        - "traefik.http.services.whoami.loadbalancer.server.port=80"
        - "traefik.http.routers.whoami.middlewares=forward-auth"
        
networks:
  traefik_public:
    external: true
```

## Serving

### Launch

Deploy dex with `docker stack deploy dex -c /var/data/dex/dex.yml`, to launch dex, and then deploy Traefik Forward Auth with `docker stack deploy traefik-forward-auth -c /var/data/traefik-forward-auth/traefik-forward-auth.yml`

Once you redeploy traefik-forward-auth with the above, it **should** use dex as an OIDC provider, authenticating you against the `staticPasswords` username and hashed password described in `config.yml` above.

### Test

Browse to <https://whoami.example.com> (*obviously, customized for your domain and having created a DNS record*), and all going according to plan, you'll be redirected to a CoreOS Dex login. Once successfully logged in, you'll be directed to the basic whoami page :thumbsup:

### Protect services

To protect any other service, ensure the service itself is exposed by Traefik. Add the following label:

```yaml
- "traefik.http.routers.radarr.middlewares=forward-auth"
```

And re-deploy your services :)

## Summary

What have we achieved? By adding an additional label to any service, we can secure any service behind our (static) OIDC provider, with minimal processing / handling overhead.

!!! summary "Summary"
    Created:

    * [X] Traefik-forward-auth configured to authenticate against Dex (static)

[^1]: You can remove the `whoami` container once you know Traefik Forward Auth is working properly

--8<-- "recipe-footer.md"
