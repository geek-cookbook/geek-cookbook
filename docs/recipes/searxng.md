---
title: Run SearXNG in Docker Swarm
description: Want to keep your search history away from BigTech? Try hosting SearXNG, the private and anonymous search engine!
recipe: SearXNG
---

# SearXNG

SearXNG is a free internet metasearch engine which aggregates results from more than 70 search services.

![SearXNG Screenshot](/images/searxng.png){ loading=lazy }

Users are neither tracked nor profiled. You can use one of the 100+ [public instances](https://searx.space/) (*including [ours](https://searxng.fnky.nz)*), or (*and really, this is why you're here, right?*) you can [run your own instance](https://docs.searxng.org/own-instance.html)

!!! question "How does SearXNG protect my privacy?"
    From the [docs](https://docs.searxng.org/own-instance.html#how-does-searxng-protect-privacy): SearXNG protects the privacy of its users in multiple ways regardless of the type of the instance (private, public). Removal of private data from search requests comes in three forms:

    :white_check_mark: removal of private data from requests going to search services <br/>
    :white_check_mark: not forwarding anything from a third party services through search services (e.g. advertisement)<br/>
    :white_check_mark: removal of private data from requests going to the result pages

    Removing private data means not sending cookies to external search engines and generating a random browser profile for every request. Thus, it does not matter if a public or private instance handles the request, because it is anonymized in both cases. IP addresses will be the IP of the instance. But SearXNG can be configured to use proxy or Tor. Result proxy is supported, too.

    SearXNG does not serve ads or tracking content unlike most search services. So private data is not forwarded to third parties who might monetize it. Besides protecting users from search services, both referring page and search query are hidden from visited result pages.

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup {{ page.meta.recipe }} data directory

First we create a directory to hold the files (*really just the persistence of settings*) which searxng will create:

```bash
mkdir /var/data/searxng
```

### Setup {{ page.meta.recipe }} environment

Create `/var/data/config/searxng/searxng.env` something like the example below..

```yaml title="/var/data/config/searxng/searxng.env"
BIND_ADDRESS=0.0.0.0:8080
BASE_URL=https://searxng.example.com/
INSTANCE_NAME="example.com's searxng instance"
AUTOCOMPLETE="false"
```

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml
version: "3.2"

services:
  
  searxng:
    image: searxng/searxng:latest
    env_file: /var/data/config/searxng/searxng.env
    volumes:
      - /var/data/searxng:/etc/searxng:rw
  
    deploy:
      replicas: 1
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv2
        - "traefik.http.routers.searxng.rule=Host(`searxng.example.com`)"
        - "traefik.http.routers.searxng.entrypoints=https"
        - "traefik.http.services.searxng.loadbalancer.server.port=8080"

    networks:
      - traefik_public
  
networks:
  traefik_public:
    external: true
```

## Serving

### Deploy {{ page.meta.recipe }}!

Deploy SearXNG by running ```docker stack deploy searxng -c <path -to-docker-compose.yml>```

Now browse to the URL you specified in `BASE_URL` (*which should match your traefik labels in the docker-compose file*), and you should be presented with your very own SearXNG interface!

## Customize {{ page.meta.recipe }}

Take a look in `/var/data/searxng`, and note that a `settings.yml` file has been created. You can customize your searXNG instance by editing `settings.yml`, making changes, and then restarting the stack with `docker service update searxng --force`.

Here are some useful customizations I've included in mine:

### Redirect YouTube to Invidious

I set the following, to automatically redirect any YouTube search results to my [Individous][invidious] instance:

```yaml
hostname_replace:
  '(.*\.)?youtube\.com$': 'in.fnky.nz'
  '(.*\.)?youtu\.be$': 'in.fnky.nz'
```

### Search YouTube via Invidious

Likewise, the following addition to the `engines` section allows my to perform an [Individous][invidious]  search directly from SearXNG:

```yaml
  - name: invidious
    engine: invidious
    base_url:
      - https://in.fnky.nz
    shortcut: in
    timeout: 3.0
    disabled: false
```

### Get {{ page.meta.recipe }} search results as RSS

It's not enabled by default, but by adding `rss` to the list of search formats (*json is an option too*), you can get search results via RSS:

```yaml
search:
  formats:
    - html
    - rss
```

#### Who would need search results via RSS?

For one, anyone who wanted to build their own crude "Google Alerts" - you'd perform the search you wanted to monitor, click the RSS download link (*or just append `&format=rss` to the search URL*), and add this link to your RSS reader. Any changes in the result will be reflected as a new RSS entry[^1]!

[^1]: Combine SearXNG's RSS results with [Huggin](/recipes/huginn/) for a more feature-full alternative to Google Alerts! 💪

{% include 'recipe-footer.md' %}
