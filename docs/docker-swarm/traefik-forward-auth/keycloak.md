---
title: SSO with traefik forward auth with Keycloak
description: Traefik forward auth can selectively SSO your Docker services against an authentication backend using OIDC, and Keycloak is a perfect, self-hosted match.
---
# Traefik Forward Auth with Keycloak for SSO

While the [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/) recipe demonstrated a quick way to protect a set of explicitly-specified URLs using OIDC credentials from a Google account, this recipe will illustrate how to use your own Keycloak instance to secure **any** URLs within your DNS domain.

!!! tip "Keycloak with Traefik"
    Did you land here from a search, looking for information about using Keycloak with Traefik? All this and more is covered in the [Keycloak][keycloak] recipe!

--8<-- "recipe-tfa-ingredients.md"

## Preparation

### Setup environment

Create `/var/data/config/traefik/traefik-forward-auth.env` as per the following example (_change "master" if you created a different realm_):

```bash
CLIENT_ID=<your keycloak client name>
CLIENT_SECRET=<your keycloak client secret>
OIDC_ISSUER=https://<your keycloak URL>/auth/realms/master
SECRET=<a random string to secure your cookie>
AUTH_HOST=<the FQDN to use for your auth host>
COOKIE_DOMAIN=<the root FQDN of your domain>
```

### Prepare the docker service config

This is a small container, you can simply add the following content to the existing `traefik-app.yml` deployed in the previous [Traefik](/docker-swarm/traefik/) recipe:

```bash
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

```bash
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

Browse to `https://whoami.example.com` (_obviously, customized for your domain and having created a DNS record_), and all going according to plan, you'll be redirected to a Keycloak login. Once successfully logged in, you'll be directed to the basic whoami page.

### Protect services

To protect any other service, ensure the service itself is exposed by Traefik (_if you were previously using an oauth_proxy for this, you may have to migrate some labels from the oauth_proxy serivce to the service itself_). Add the following 3 labels:

```yaml
- traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
- traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
- traefik.frontend.auth.forward.trustForwardHeader=true
```

And re-deploy your services :)

## Summary

What have we achieved? By adding an additional three simple labels to any service, we can secure any service behind our Keycloak OIDC provider, with minimal processing / handling overhead.

!!! summary "Summary"
    Created:

    * [X] Traefik-forward-auth configured to authenticate against Keycloak

[^1]: Keycloak is very powerful. You can add 2FA and all other clever things outside of the scope of this simple recipe ;)

### Keycloak vs Authelia

[Keycloak][keycloak] is the "big daddy" of self-hosted authentication platforms - it has a beautiful GUI, and a very advanced and mature featureset. Like Authelia, Keycloak can [use an LDAP server](/recipes/keycloak/authenticate-against-openldap/) as a backend, but _unlike_ Authelia, Keycloak allows for 2-way sync between that LDAP backend, meaning Keycloak can be used to _create_ and _update_ the LDAP entries (*Authelia's is just a one-way LDAP lookup - you'll need another tool to actually administer your LDAP database*).

{% include 'recipe-footer.md' %}
