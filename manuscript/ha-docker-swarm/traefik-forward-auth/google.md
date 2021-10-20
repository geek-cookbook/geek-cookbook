# Traefik Forward Auth using Google

[Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/) is incredibly useful to secure services with an additional layer of authentication, provided by an OIDC-compatible provider. The simplest possible provider is a self-hosted instance of [Dex][dex], configured with a static username and password. This is not much use if you want to provide "normies" access to your services though - a better solution would be to validate their credentials against an existing trusted public source.

This recipe will illustrate how to point Traefik Forward Auth to Google, confirming that the requestor has a valid Google account (*and that said account is permitted to access your services!*)

--8<-- "recipe-tfa-ingredients.md"

## Preparation

### Obtain OAuth credentials

#### TL;DR

Log into <https://console.developers.google.com/>, create a new project then search for and select "**Credentials**" in the search bar.

 Fill out the "OAuth Consent Screen" tab, and then click, "**Create Credentials**" > "**OAuth client ID**". Select "**Web Application**", fill in the name of your app, skip "**Authorized JavaScript origins**" and fill "**Authorized redirect URIs**" with either all the domains you will allow authentication from, appended with the url-path (*e.g. <https://radarr.example.com/_oauth>, <https://radarr.example.com/_oauth>, etc*), or if you don't like frustration, use a "auth host" URL instead, like "*<https://auth.example.com/_oauth>*" (*see below for details*)

#### Monkey see, monkey do 🙈

Here's a [screencast I recorded](https://static.funkypenguin.co.nz/2021/screencast_2021-01-29_22-29-33.gif) of the OIDC credentias setup in Google Developer Console

!!! tip
    Store your client ID and secret safely - you'll need them for the next step.

### Prepare environment

Create `/var/data/config/traefik-forward-auth/traefik-forward-auth.env` as follows:

```bash
PROVIDERS_GOOGLE_CLIENT_ID=<your client id>
PROVIDERS_GOOGLE_CLIENT_SECRET=<your client secret>
SECRET=<a random string, make it up>
# comment out AUTH_HOST if you'd rather use individual redirect_uris (slightly less complicated but more work)
AUTH_HOST=auth.example.com
COOKIE_DOMAINS=example.com
WHITELIST=you@yourdomain.com, me@mydomain.com
```

### Prepare the docker service config

Create `/var/data/config/traefik-forward-auth/traefik-forward-auth.yml` as follows:

```yaml
  traefik-forward-auth:
    image: thomseddon/traefik-forward-auth:2.1.0
    env_file: /var/data/config/traefik-forward-auth/traefik-forward-auth.env
    networks:
      - traefik_public
    deploy:
      labels # you only need these if you're using an auth host
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

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
```

If you're not confident that forward authentication is working, add a simple "whoami" test container to the above .yml, to help debug traefik forward auth, before attempting to add it to a more complex container.

```yaml
  # This simply validates that traefik forward authentication is working
  whoami:
    image: containous/whoami
    networks:
      - traefik_public
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:whoami.example.com
        - "traefik.http.services.linx.loadbalancer.server.port=80"
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true        

        # traefikv2
        - "traefik.http.routers.whoami.rule=Host(`whoami.example.com`)"
        - "traefik.http.routers.whoami.entrypoints=https"
        - "traefik.http.services.whoami.loadbalancer.server.port=80"
        - "traefik.http.routers.whoami.middlewares=forward-auth" # this line enforces traefik-forward-auth  

```

--8<-- "premix-cta.md"

## Serving

### Launch

Deploy traefik-forward-auth with ```docker stack deploy traefik-forward-auth -c /var/data/traefik-forward-auth/traefik-forward-auth.yml```

### Test

Browse to <https://whoami.example.com> (*obviously, customized for your domain and having created a DNS record*), and all going according to plan, you should be redirected to a Google login. Once successfully logged in, you'll be directed to the basic whoami page.

## Summary

What have we achieved? By adding an additional three simple labels to any service, we can secure any service behind our choice of OAuth provider, with minimal processing / handling overhead.

!!! summary "Summary"
    Created:

    * [X] Traefik-forward-auth configured to authenticate against an OIDC provider

[^1]: Be sure to populate `WHITELIST` in `traefik-forward-auth.env`, else you'll happily be granting **any** authenticated Google account access to your services!

--8<-- "recipe-footer.md"
