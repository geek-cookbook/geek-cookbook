# Using Traefik Forward Auth with Dex

[Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/) is incredibly useful to secure services with an additional layer of authentication, provided by an OIDC-compatible provider. The simplest possible provides is CoreOS's Dex, configured with a static user/pass.

## Ingredients

!!! Summary
    Existing:

    * [X] [Traefik](/recipes/keycloak/) recipe deployed successfully, with a [local user](/recipes/keycloak/create-user/) and an [OIDC client](/recipes/keycloak/setup-oidc-provider/)

    New:

    * [ ] DNS entry for your auth host (*"auth.yourdomain.com" is a good choice*), pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP

## Preparation

--8<--- "recipe-authhost-mode.md"

### Setup environment

Create `/var/data/config/traefik/traefik-forward-auth.env` as follows (_change "master" if you created a different realm_):

```
CLIENT_ID=<your keycloak client name>
CLIENT_SECRET=<your keycloak client secret>
OIDC_ISSUER=https://<your keycloak URL>/auth/realms/master
SECRET=<a random string to secure your cookie>
AUTH_HOST=<the FQDN to use for your auth host>
COOKIE_DOMAIN=<the root FQDN of your domain>
```

### Prepare the docker service config

This is a small container, you can simply add the following content to the existing `traefik-app.yml` deployed in the previous [Traefik](/ha-docker-swarm/traefik/) recipe:

```
  traefik-forward-auth:
    image: funkypenguin/traefik-forward-auth
    env_file: /var/data/config/traefik/traefik-forward-auth.env
    networks:
      - traefik_public
    deploy:
      labels:
        - traefik.port=4181
        - traefik.frontend.rule=Host:auth.example.com
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.trustForwardHeader=true
```

If you're not confident that forward authentication is working, add a simple "whoami" test container, to help debug traefik forward auth, before attempting to add it to a more complex container.

```
  # This simply validates that traefik forward authentication is working
  whoami:
    image: containous/whoami
    networks:
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:whoami.example.com
        - traefik.port=80
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true
```

--8<-- "premix-cta.md"

## Serving

### Launch

Redeploy traefik with `docker stack deploy traefik-app -c /var/data/traefik/traeifk-app.yml`, to launch the traefik-forward-auth container.

### Test

Browse to https://whoami.example.com (_obviously, customized for your domain and having created a DNS record_), and all going according to plan, you'll be redirected to a KeyCloak login. Once successfully logged in, you'll be directed to the basic whoami page.

### Protect services

To protect any other service, ensure the service itself is exposed by Traefik (_if you were previously using an oauth_proxy for this, you may have to migrate some labels from the oauth_proxy serivce to the service itself_). Add the following 3 labels:

```
- traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
- traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
- traefik.frontend.auth.forward.trustForwardHeader=true
```

And re-deploy your services :)

## Summary

What have we achieved? By adding an additional three simple labels to any service, we can secure any service behind our KeyCloak OIDC provider, with minimal processing / handling overhead.

!!! summary "Summary"
Created:

    * [X] Traefik-forward-auth configured to authenticate against KeyCloak

[^1]: KeyCloak is very powerful. You can add 2FA and all other clever things outside of the scope of this simple recipe ;)

--8<-- "recipe-footer.md"