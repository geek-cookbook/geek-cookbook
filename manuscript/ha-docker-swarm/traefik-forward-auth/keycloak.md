# Using Traefik Forward Auth with KeyCloak

While the [Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/) recipe demonstrated a quick way to protect a set of explicitly-specified URLs using OIDC credentials from a Google account, this recipe will illustrate how to use your own KeyCloak instance to secure **any** URLs within your DNS domain.

## Ingredients

!!! Summary
    Existing:

    * [X] [KeyCloak](/recipes/keycloak/) recipe deployed successfully, with a [local user](/recipes/keycloak/create-user/) and an [OIDC client](/recipes/keycloak/setup-oidc-provider/)
    
    New:

    * [ ] DNS entry for your auth host (*"auth.yourdomain.com" is a good choice*), pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP

## Preparation

### What is AuthHost mode

Under normal OIDC auth, you have to tell your auth provider which URLs it may redirect an authenticated user back to, post-authentication. This is a security feture of the OIDC spec, preventing a malicious landing page from capturing your session and using it to impersonate you. When you're securing many URLs though, explicitly listing them can be a PITA. 

[@thomaseddon's traefik-forward-auth](https://github.com/thomseddon/traefik-forward-auth) includes an ingenious mechanism to simulate an "*auth host*" in your OIDC authentication, so that you can protect an unlimited amount of DNS names (*with a common domain suffix*), without having to manually maintain a list.

#### How does it work?

Say you're protecting **radarr.example.com**. When you first browse to **https://radarr.example.com**, Traefik forwards your session to traefik-forward-auth, to be authenticated. Traefik-forward-auth redirects you to your OIDC provider's login (*KeyCloak, in this case*), but instructs the OIDC provider to redirect a successfully authenticated session **back** to **https://auth.example.com/_oauth**, rather than to **https://radarr.example.com/_oauth**.

When you successfully authenticate against the OIDC provider, you are redirected to the "*redirect_uri*" of https://auth.example.com. Again, your request hits Traefik, whichforwards the session to traefik-forward-auth, which **knows** that you've just been authenticated (*cookies have a role to play here*). Traefik-forward-auth also knows the URL of your **original** request (*thanks to the X-Forwarded-Whatever header*). Traefik-forward-auth redirects you to your original destination, and everybody is happy.

This clever workaround only works under 2 conditions:


1. Your "auth host" has the same domain name as the hosts you're protecting (*i.e., auth.example.com protecting radarr.example.com*)
2. You explictly tell traefik-forward-auth to use a cookie authenticating your **whole** domain (*i.e. example.com*)

### Setup environment

Create `/var/data/config/traefik/traefik-forward-auth.env` as follows (*change "master" if you created a different realm*):

```
CLIENT_ID=<your keycloak client name>
CLIENT_SECRET=<your keycloak client secret>
OIDC_ISSUER=https://<your keycloak URL>/auth/realms/master
SECRET=<a random string to secure your cookie>
AUTH_HOST=<the FQDN to use for your auth host>
COOKIE_DOMAIN=<the root FQDN of your domain>
```

### Prepare the docker service config

This is a small container, you can simply add the following content to the existing `traefik-app.yml` deployed in the previous [Traefik](/recipes/traefik/) recipe:

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

!!! tip
        I share (_with my [sponsors](https://github.com/sponsors/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that sponsors can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

## Serving

### Launch

Redeploy traefik with ```docker stack deploy traefik-app -c /var/data/traefik/traeifk-app.yml```, to launch the traefik-forward-auth container. 

### Test

Browse to https://whoami.example.com (*obviously, customized for your domain and having created a DNS record*), and all going according to plan, you'll be redirected to a KeyCloak login. Once successfully logged in, you'll be directed to the basic whoami page.

### Protect services

To protect any other service, ensure the service itself is exposed by Traefik (*if you were previously using an oauth_proxy for this, you may have to migrate some labels from the oauth_proxy serivce to the service itself*). Add the following 3 labels:

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



## Chef's Notes 📓

1. KeyCloak is very powerful. You can add 2FA and all other clever things outside of the scope of this simple recipe ;)
