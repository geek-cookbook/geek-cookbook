# Traefik Forward Auth

Now that we have Traefik deployed, automatically exposing SSL access to our Docker Swarm services using LetsEncrypt wildcard certificates, let's pause to consider that we may not _want_ some services exposed directly to the internet...

..Wait, why not? Well, Traefik doesn't provide any form of authentication, it simply secures the **transmission** of the service between Docker Swarm and the end user. If you were to deploy a service with no native security (*[Radarr](/recipes/autopirate/radarr/) or [Sonarr](/recipes/autopirate/sonarr/) come to mind*), then anybody would be able to use it! Even services which _may_ have a layer of authentication **might** not be safe to expose publically - often open source projects may be maintained by enthusiasts who happily add extra features, but just pay lip service to security, on the basis that "*it's the user's problem to secure it in their own network*".

Some of the platforms we use on our swarm may have strong, proven security to prevent abuse. Techniques such as rate-limiting (*to defeat brute force attacks*) or even support 2-factor authentication (*tiny-tiny-rss or Wallabag support this)*.

Other platforms may provide **no authentication** (Traefik's web UI for example), or minimal, un-proven UI authentication which may have been added as an afterthought.

Still other platforms may hold such sensitive data (*i.e., NextCloud*), that we'll feel more secure by putting an additional authentication layer in front of them.

This is the role of Traefik Forward Auth.

## How does it work?

**Normally**, Traefik proxies web requests directly to individual web apps running in containers. The user talks directly to the webapp, and the webapp is responsible for ensuring appropriate authentication.

When employing Traefik Forward Auth as "[middleware](https://doc.traefik.io/traefik/middlewares/forwardauth/)", the forward-auth process sits in the middle of this transaction - traefik receives the incoming request, "checks in" with the auth server to determine whether or not further authentication is required. If the user is authenticated, the auth server returns a 200 response code, and Traefik is authorized to forward the request to the backend. If not, traefik passes the auth server response back to the user - this process will usually direct the user to an authentication provider (_GitHub, Google, etc_), so that they can perform a login.

Illustrated below:
![Traefik Forward Auth](../images/traefik-forward-auth.png)

The advantage under this design is additional security. If I'm deploying a web app which I expect only an authenticated user to require access to (*unlike something intended to be accessed publically, like [Linx](/recipes/linx/)*), I'll pass the request through Traefik Forward Auth. The overhead is negligible, and the additional layer of security is well-worth it.

## What is AuthHost mode

Under normal OIDC auth, you have to tell your auth provider which URLs it may redirect an authenticated user back to, post-authentication. This is a security feture of the OIDC spec, preventing a malicious landing page from capturing your session and using it to impersonate you. When you're securing many URLs though, explicitly listing them can be a PITA.

[@thomaseddon's traefik-forward-auth](https://github.com/thomseddon/traefik-forward-auth) includes an ingenious mechanism to simulate an "_auth host_" in your OIDC authentication, so that you can protect an unlimited amount of DNS names (_with a common domain suffix_), without having to manually maintain a list.

#### How does it work?

Say you're protecting **radarr.example.com**. When you first browse to **https://radarr.example.com**, Traefik forwards your session to traefik-forward-auth, to be authenticated. Traefik-forward-auth redirects you to your OIDC provider's login (_KeyCloak, in this case_), but instructs the OIDC provider to redirect a successfully authenticated session **back** to **https://auth.example.com/_oauth**, rather than to **https://radarr.example.com/_oauth**.

When you successfully authenticate against the OIDC provider, you are redirected to the "_redirect_uri_" of https://auth.example.com. Again, your request hits Traefik, which forwards the session to traefik-forward-auth, which **knows** that you've just been authenticated (_cookies have a role to play here_). Traefik-forward-auth also knows the URL of your **original** request (_thanks to the X-Forwarded-Whatever header_). Traefik-forward-auth redirects you to your original destination, and everybody is happy.

This clever workaround only works under 2 conditions:

1. Your "auth host" has the same domain name as the hosts you're protecting (_i.e., auth.example.com protecting radarr.example.com_)
2. You explictly tell traefik-forward-auth to use a cookie authenticating your **whole** domain (_i.e. example.com_)

## Authentication Providers

Traefik Forward Auth needs to authenticate an incoming user against a provider. A provider can be something as simple as a self-hosted [dex][tfa-dex] instance with a single static username/password, or as complex as a [KeyCloak][keycloak] instance backed by [OpenLDAP][openldap]. Here are some options, in increasing order of complexity...

* [Authenticate against a self-hosted Dex instance with static usernames and passwords][tfa-dex-static]
* [Authenticate against a whitelist of Google accounts][tfa-google]
* [Authenticate against a self-hosted KeyCloak instance][tfa-keycloak]

--8<-- "recipe-footer.md"

[^1]: Authhost mode is specifically handy for Google authentication, since Google doesn't permit wildcard redirect_uris, like [KeyCloak][keycloak] does.