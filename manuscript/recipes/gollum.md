hero: Gollum - A recipe for your own git-based wiki

# Gollum

Gollum is a simple wiki system built on top of Git. A Gollum Wiki is simply a git repository (_either bare or regular_) of a specific nature:

* A Gollum repository's contents are human-editable, unless the repository is bare.
* Pages are unique text files which may be organized into directories any way you choose.
* Other content can also be included, for example images, PDFs and headers/footers for your pages.

Gollum pages:

* May be written in a variety of markups.
* Can be edited with your favourite system editor or IDE (_changes will be visible after committing_) or with the built-in web interface.
* Can be displayed in all versions (_commits_).


![Gollum Screenshot](../images/gollum.png)

As you'll note in the (_real world_) screenshot above, my requirements for a personal wiki are:

* Portable across my devices
* Supports images
* Full-text search
* Supports inter-note links
* Revision control

Gollum meets all these requirements, and as an added bonus, is extremely fast and lightweight.

!!! note
    Since Gollum itself offers no user authentication, this design secures gollum behind an [oauth2 proxy](/reference/oauth_proxy/), so that in order to gain access to the Gollum UI at all, oauth2 authentication (_to GitHub, GitLab, Google, etc_) must have already occurred.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need an empty git repository in /var/data/gollum for our data:

```
mkdir /var/data/gollum
cd /var/data/gollum
git init
```

### Prepare environment

1. Choose an oauth provider, and obtain a client ID and secret
2. Create gollum.env, and populate with the following variables (_you can make the cookie secret whatever you like_)

```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  app:
    image: dakue/gollum
    volumes:
     - /var/data/gollum:/gollum
    networks:
    - internal
    command: |
      --allow-uploads
      --emoji
      --user-icons gravatar

  proxy:
    image: a5huynh/oauth2_proxy
    env_file : /var/data/config/gollum/gollum.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:gollum.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=4180
    volumes:
      - /var/data/config/gollum/authenticated-emails.txt:/authenticated-emails.txt
    command: |
      -cookie-secure=false
      -upstream=http://app:4567
      -redirect-url=https://gollum.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.9.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Gollum stack

Launch the Gollum stack by running ```docker stack deploy gollum -c <path-to-docker-compose.yml>```

Authenticate against your OAuth provider, and then start editing your wiki!

[^1]: In the current implementation, Gollum is a "single user" tool only. The contents of the wiki are saved as markdown files under /var/data/gollum, and all the git commits are currently "Anonymous"

--8<-- "recipe-footer.md"