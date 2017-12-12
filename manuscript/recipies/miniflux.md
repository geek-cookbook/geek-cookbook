hero: Miniflux - A recipe for a lightweight minimalist RSS reader

# Miniflux

Miniflux is a lightweight RSS reader, developed by [Frédéric Guillot](https://github.com/fguillot). (Who also happens to be the developer of the favorite Open Source Kanban app, [Kanboard](https://kanboard.net/))

I've [reviewed Miniflux in detail on my blog](https://www.funkypenguin.co.nz/review/miniflux-lightweight-self-hosted-rss-reader/), but features (among many) that I appreciate:

* Compatible with the Fever API, read your feeds through existing mobile and desktop clients (_This is the killer feature for me. I hardly ever read RSS on my desktop, I typically read on my iPhone or iPad, using [Fiery Feeds](http://cocoacake.net/apps/fiery/) or my new squeeze, [Unread](https://www.goldenhillsoftware.com/unread/)_)
* Send your bookmarks to Pinboard, Wallabag, Shaarli or Instapaper (_I use this to automatically pin my bookmarks for collection on my [blog](https://www.funkypenguin.co.nz/blog/)_)
* Feeds can be configured to download a "full" version of the content (_rather than an excerpt_)
* Use the Bookmarklet to subscribe to a website directly from any browsers


## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design

## Preparation

### Setup data locations

Create the location for the bind-mount of the application data, so that it's persistent:

```
mkdir -p /var/data/miniflux
```


### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

```
version: '3'

services:
  miniflux:
    image: saghul/miniflux
    volumes:
     - /etc/localtime:/etc/localtime:ro
     - /var/data/miniflux/:/config/
    networks:
    - traefik
    deploy:
      labels:
        - traefik.frontend.rule=Host:miniflux.example.com
        - traefik.docker.network=traefik
        - traefik.port=80

networks:
  traefik:
    external: true
```


## Serving

### Launch Miniflux stack

Launch the Miniflux stack by running ```docker stack deploy miniflux -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. Default credentials are admin/admin, after which you can change (under 'profile') and add more users.

## Chef's Notes

1. I chose [saghul/miniflux](https://hub.docker.com/r/saghul/miniflux/)'s over the "official" [miniflux/miniflux](https://hub.docker.com/r/miniflux/miniflux/) image, because currently the official image doesn't log to stdout (which you want, for docker logging commands), and because I have an expectation that nginx is more lightweight (faster) than apache.
2. Find the bookmarklet under the "about" page. I know, it took me ages too.


## Your comments?
