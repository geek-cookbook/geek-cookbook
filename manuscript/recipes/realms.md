# Realms

Realms is a git-based wiki (_like [Gollum](/recipes/gollum/), but with basic authentication and registration_)

![Realms Screenshot](../images/realms.png)

Features include:

* Built with Bootstrap 3.
* Markdown (w/ HTML Support).
* Syntax highlighting (Ace Editor).
* Live preview.
* Collaboration (TogetherJS / Firepad).
* Drafts saved to local storage.
* Handlebars for templates and logic.

!!! warning "Project likely abandoned"

    In my limited trial, Realms seems _less_ useful than [Gollum](/recipes/gollum/) for my particular use-case (_i.e., you're limited to markdown syntax only_), but other users may enjoy the basic user authentication and registration features, which Gollum lacks.

    Also of note is that the docker image is 1.17GB in size, and the handful of commits to the [source GitHub repo](https://github.com/scragg0x/realms-wiki/commits/master)  in the past year has listed TravisCI build failures. This has many of the hallmarks of an abandoned project, to my mind.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

Since we'll start with a basic Realms install, let's just create a single directory to hold the realms (SQLite) data:

```
mkdir /var/data/realms/
```

Create realms.env, and populate with the following variables (_if you intend to use an [oauth_proxy](/reference/oauth_proxy) to double-secure your installation, which I recommend_)
```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3"

services:
  realms:
    image: realms/realms-wiki:latest
    env_file: /var/data/config/realms/realms.env
    volumes:
      - /var/data/realms:/home/wiki/data
    networks:
      - internal

  realms_proxy:
    image: funkypenguin/oauth2_proxy:latest
    env_file : /var/data/config/realms/realms.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:realms.funkypenguin.co.nz
        - traefik.docker.network=traefik_public
        - traefik.port=4180
    volumes:
      - /var/data/config/realms/authenticated-emails.txt:/authenticated-emails.txt
    command: |
      -cookie-secure=false
      -upstream=http://realms:5000
      -redirect-url=https://realms.funkypenguin.co.nz
      -http-address=http://0.0.0.0:4180
      -email-domain=funkypenguin.co.nz
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.35.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Realms stack

Launch the Wekan stack by running ```docker stack deploy realms -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, authenticate against oauth_proxy, and you're immediately presented with Realms wiki, waiting for a fresh edit ;)

[^1]: If you wanted to expose the Realms UI directly, you could remove the oauth2_proxy from the design, and move the traefik_public-related labels directly to the realms container. You'd also need to add the traefik_public network to the realms container.
[^2]: The inclusion of Realms was due to the efforts of @gkoerk in our [Discord server](http://chat.funkypenguin.co.nz). Thanks gkoerk!

--8<-- "recipe-footer.md"