# Traefik Forward Auth

Some of the platforms we use on our swarm may have strong, proven security to prevent abuse. Techniques such as rate-limiting (*to defeat brute force attacks*) or even support 2-factor authentication (*tiny-tiny-rss or Wallabag support this)*.

Other platforms may provide **no authentication** (Traefik's web UI for example), or minimal, un-proven UI authentication which may have been added as an afterthought.

Still other platforms may hold such sensitive data (i.e., NextCloud), that we'll feel more secure by putting an additional authentication layer in front of them.

This is the role of Traefik Forward Auth.

## How does it work?

**Normally**, Traefik proxies web requests directly to individual web apps running in containers. The user talks directly to the webapp, and the webapp is responsible for ensuring appropriate authentication.

When employing Traefik Forward Auth as "[middleware](https://doc.traefik.io/traefik/middlewares/forwardauth/)", the forward-auth process sits in the middle of this transaction - traefik receives the incoming request, "checks in" with the auth server to determine whether or not further authentication is required. If the user is authenticated, the auth server returns a 200 response code, and Traefik is authorized to forward the request to the backend. If not, traefik passes the auth server response back to the user - this process will usually direct the user to an authentication provider (_GitHub, Google, etc_), so that they can perform a login.

Illustrated below:
![Traefik Forward Auth](../images/traefik-forward-auth.png)

The advantage under this design is additional security. If I'm deploying a web app which I expect only an authenticated user to require access to (*unlike something intended to be accessed publically, like [Linx](/recipes/linx/)*), I'll pass the request through Traefik Forward Auth. The overhead is negligible, and the additional layer of security is well-worth it.

## Authentication Providers

Here are some recipes, in descending order of complexity:

### Dex

See [Using Traefik Forward Auth with Dex](/recipes/traefik-forward-auth/dex/)

### Google

See [Using Traefik Forward Auth with Google](/recipes/traefik-forward-auth/google/)

### KeyCloak

See [Using Traefik Forward Auth with KeyCloak](/recipes/traefik-forward-auth/keycloak/)
