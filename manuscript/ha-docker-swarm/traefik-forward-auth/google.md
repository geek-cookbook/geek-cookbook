# Traefik Forward Auth using Google

Now that we have Traefik deployed, automatically exposing SSL access to our Docker Swarm services using LetsEncrypt wildcard certificates, let's pause to consider that we may not _want_ some services exposed directly to the internet...

..Wait, why not? Well, Traefik doesn't provide any form of authentication, it simply secures the **transmission** of the service between Docker Swarm and the end user. If you were to deploy a service with no native security (*[Radarr](/recipes/autopirate/radarr/) or [Sonarr](/recipes/autopirate/sonarr/) come to mind*), then anybody would be able to use it! Even services which _may_ have a layer of authentication **might** not be safe to expose publically - often open source projects may be maintained by enthusiasts who happily add extra features, but just pay lip service to security, on the basis that "*it's the user's problem to secure it in their own network*".

To give us confidence that **we** can access our services, but BadGuys(tm) cannot, we'll deploy a layer of authentication **in front** of Traefik, using [Forward Authentication](https://docs.traefik.io/configuration/entrypoints/#forward-authentication). You can use your own  [KeyCloak](/recipes/keycloak/) instance for authentication, but to lower the barrier to entry, this recipe will assume you're authenticating against your own Google account.

## Ingredients

!!! summary "Ingredients"
    Existing:

    * [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph)
    * [X] [Traefik](/ha-docker-swarm/traefik/) configured per design

    New:

    * [ ] Client ID and secret from an OpenID-Connect provider (Google, [KeyCloak](/recipes/keycloak/), Microsoft, etc..)

## Preparation

### Obtain OAuth credentials

!!! note
    This recipe will demonstrate using Google OAuth for traefik forward authentication, but it's also possible to use a self-hosted KeyCloak instance - see the [KeyCloak OIDC Provider](/recipes/keycloak/setup-oidc-provider/) recipe for more details!

Log into https://console.developers.google.com/, create a new project then search for and select "**Credentials**" in the search bar. 

Fill out the "OAuth Consent Screen" tab, and then click, "**Create Credentials**" > "**OAuth client ID**". Select "**Web Application**", fill in the name of your app, skip "**Authorized JavaScript origins**" and fill "**Authorized redirect URIs**" with either all the domains you will allow authentication from, appended with the url-path (*e.g. https://radarr.example.com/_oauth, https://radarr.example.com/_oauth, etc*), or if you don't like frustration, use a "auth host" URL instead, like "*https://auth.example.com/_oauth*" (*see below for details*)

!!! tip
    Store your client ID and secret safely - you'll need them for the next step.

--8<--- "recipe-authhost-mode.md"

### Prepare environment

Create `/var/data/config/traefik-forward-auth/traefik-forward-auth.env` as follows:

```
PROVIDERS_GOOGLE_CLIENT_ID=<your client id>
PROVIDERS_GOOGLE_CLIENT_SECRET=<your client secret>
SECRET=<a random string, make it up>
# comment out AUTH_HOST if you'd rather use individual redirect_uris (slightly less complicated but more work)
AUTH_HOST=auth.example.com
COOKIE_DOMAINS=example.com
```

### Prepare the docker service config

Create `/var/data/config/traefik-forward-auth/traefik-forward-auth.yml` as follows:

```
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

```
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

Browse to https://whoami.example.com (*obviously, customized for your domain and having created a DNS record*), and all going according to plan, you should be redirected to a Google login. Once successfully logged in, you'll be directed to the basic whoami page.

## Summary

What have we achieved? By adding an additional three simple labels to any service, we can secure any service behind our choice of OAuth provider, with minimal processing / handling overhead.

!!! summary "Summary"
    Created:

    * [X] Traefik-forward-auth configured to authenticate against an OIDC provider

[^1]: Traefik forward auth replaces the use of [oauth_proxy containers](/reference/oauth_proxy/) found in some of the existing recipes
[^2]: I reviewed several implementations of forward authenticators for Traefik, but found most to be rather heavy-handed, or specific to a single auth provider. @thomaseddon's go-based docker image is 7MB in size, and can be extended to work with any OIDC provider.

--8<-- "recipe-footer.md"