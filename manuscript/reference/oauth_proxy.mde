# OAuth proxy

Some of the platforms we use on our swarm may have strong, proven security to prevent abuse. Techniques such as rate-limiting (to defeat brute force attacks) or even support 2-factor authentication (tiny-tiny-rss or Wallabag support this).

Other platforms may provide **no authentication** (Traefik's web UI for example), or minimal, un-proven UI authentication which may have been added as an afterthought.

Still platforms may hold such sensitive data (i.e., NextCloud), that we'll feel more secure by putting an additional authentication layer in front of them.

This is the role of the OAuth proxy.

## How does it work?

**Normally**, Traefik proxies web requests directly to individual web apps running in containers. The user talks directly to the webapp, and the webapp is responsible for ensuring appropriate authentication.

When employing the **OAuth proxy** , the proxy sits in the middle of this transaction - traefik sends the web client to the OAuth proxy, the proxy authenticates the user against a 3rd-party source (_GitHub, Google, etc_), and then passes authenticated requests on to the web app in the container.

Illustrated below:
![OAuth proxy](/images/oauth_proxy.png)

The advantage under this design is additional security. If I'm deploying a web app which I expect only myself to require access to, I'll put the oauth_proxy in front of it. The overhead is negligible, and the additional layer of security is well-worth it.

## Ingredients

## Preparation

### OAuth provider

OAuth Proxy currently supports the following OAuth providers:

* Google (default)
* Azure
* Facebook
* GitHub
* GitLab
* LinkedIn
* MyUSA

Follow the [instructions](https://github.com/bitly/oauth2_proxy) to setup your oauth provider. You need to setup a unique key/secret for **each** instance of the proxy you want to run, since in each case the callback URL will differ.

### Authorized emails file

There are a variety of options with oauth_proxy re which email addresses (authenticated against your oauth provider) should be permitted access. You can permit access based on email domain (*@gmail.com), individual email address (batman@gmail.com), or based on provider-specific groups (_i.e., a GitHub organization_)

The most restrictive configuration allows access on a per-email address basis, which is illustrated below:

I created **/var/data/oauth_proxy/authenticated-emails.txt**, and add my own email address to the first line.

### Configure stack

You'll need to define a service for the oauth_proxy in every stack which you want to protect. Here's an example from the [Wekan](/recipes/wekan/) recipe:

```
proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/wekan/wekan.env
  networks:
    - traefik
    - internal
  deploy:
    labels:
      - traefik.frontend.rule=Host:wekan.funkypenguin.co.nz
      - traefik.docker.network=traefik
      - traefik.port=4180
  volumes:
    - /var/data/oauth_proxy/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://wekan:80
    -redirect-url=https://wekan.funkypenguin.co.nz
    -http-address=http://0.0.0.0:4180
    -email-domain=funkypenguin.co.nz
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
```

Note above how:
* Labels are required to tell Traefik to forward the traffic to the proxy, rather than the backend container running the app
* An environment file is defined, but..
* The redirect URL must still be passed to the oauth_proxy in the command argument