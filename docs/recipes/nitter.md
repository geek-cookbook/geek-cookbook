---
description: Neat one-sentence description of recipe for social media previews
recipe: Nitter
title: Short, punchy title for search engine results / social previews
image: /images/nitter.png
status: new
---

# {{ page.meta.recipe }} on Docker Swarm

Are you becoming increasingly wary of Twitter, [post-space-Karen](https://knowyourmeme.com/editorials/guides/who-is-space-karen-and-why-is-the-nickname-trending-on-twitter)? Try Nitter, a (*read-only*) private frontend to Twitter, supporting username and keyword search, with geeky features like RSS and theming!

!!! note "But what about Twitter's API Developer rules?"
    In a [GitHub issue](https://github.com/zedeus/nitter/issues/783#issuecomment-1414810634) querying whether Nitter would be affected by Twitter's API schenanigans, developer @zedeus pointed out that Nitter uses an **unofficial** API, and responded concisely:

    > I'm not bound by that developer agreement, so whatevs.

    \*micdrop\*

![Screenshot of {{ page.meta.recipe }}]({{ page.meta.image }}){ loading=lazy }

[Nitter](https://github.com/zedeus/nitter) is a free and open source alternative Twitter front-end focused on privacy and performance, with features including:

:white_check_mark: No JavaScript or ads<br/>
:white_check_mark: All requests go through the backend, client never talks to Twitter<br/>
:white_check_mark: Prevents Twitter from tracking your IP or JavaScript fingerprint<br/>
:white_check_mark: Uses Twitter's unofficial API (*no rate limits or developer account required*)<br/>
:white_check_mark: Lightweight (for @nim_lang, 60KB vs 784KB from twitter.com)<br/>
:white_check_mark: RSS feeds, Themes, Mobile support (*responsive design*)<br/>

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

First we create a directory to hold the data which Redis will cache for nitter:

```bash
mkdir /var/data/nitter
```

### Create config file

Nitter is configured using a flat text file, so create `/var/data/config/nitter/nitter.conf` from the [example at in the repo](https://github.com/zedeus/nitter/blob/master/nitter.example.conf), and then we'll mount it (*read-only*) into the container, below. Here's what it looks like, if you'd prefer a copy-paste (*the only critical setting is `redisHost` be set to `redis`*)

```bash title="/var/data/config/nitter/nitter.conf"
[Server]
address = "0.0.0.0"
port = 8080
https = true  # disable to enable cookies when not using https
httpMaxConnections = 100
staticDir = "./public"
title = "example.com's nitter"
hostname = "nitter.example.com"

[Cache]
listMinutes = 240  # how long to cache list info (not the tweets, so keep it high)
rssMinutes = 10  # how long to cache rss queries
redisHost = "redis" #(1)!
redisPort = 6379
redisPassword = ""
redisConnections = 20  # connection pool size
redisMaxConnections = 30
# max, new connections are opened when none are available, but if the pool size
# goes above this, they're closed when released. don't worry about this unless
# you receive tons of requests per second

[Config]
hmacKey = "imasecretsecretkey"  # random key for cryptographic signing of video urls
base64Media = false  # use base64 encoding for proxied media urls
enableRSS = true  # set this to false to disable RSS feeds
enableDebug = false  # enable request logs and debug endpoints
proxy = ""  # http/https url, SOCKS proxies are not supported
proxyAuth = ""
tokenCount = 10
# minimum amount of usable tokens. tokens are used to authorize API requests,
# but they expire after ~1 hour, and have a limit of 187 requests.
# the limit gets reset every 15 minutes, and the pool is filled up so there's
# always at least $tokenCount usable tokens. again, only increase this if
# you receive major bursts all the time

# Change default preferences here, see src/prefs_impl.nim for a complete list
[Preferences]
theme = "Nitter"
replaceTwitter = "nitter.example.com" #(2)!
replaceYouTube = "piped.video" #(3)!
replaceReddit = "teddit.net" #(4)!
proxyVideos = true
hlsPlayback = false
infiniteScroll = false
```

1. Note that because we're using docker swarm, we can simply use `redis` as the target redis host
2. Set this to your Nitter URL to have Nitter rewrite twitter.com links in tweets to itself
3. If you've setup [Invidious][invidious], then you can have Nitter rewrite any YouTube URLs to your Invidious instance
4. I don't know what Teddit is (*yet*), but I assume it's a private Reddit proxy, and I hope that it has a teddy bear as its logo! :bear:

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml
version: "3.2" # https://docs.docker.com/compose/compose-file/compose-versioning/#version-3

services:

  nitter:
    image: zedeus/nitter:latest
    volumes:
      - /var/data/config/nitter/nitter.conf:/src/nitter.conf:Z,ro
    deploy:
      replicas: 1
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public
        - traefik.http.routers.nitter.rule=Host(`nitter.example.com`)
        - traefik.http.routers.nitter.entrypoints=https
        - traefik.http.services.nitter.loadbalancer.server.port=8080
    networks:
      - internal
      - traefik_public

  redis:
    image: redis:6-alpine
    command: redis-server --save 60 1 --loglevel warning
    volumes:
      - /var/data/nitter/redis:/data
    networks:
      - internal

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.24.0/24
```

--8<-- "reference-networks.md"

!!! question "Shouldn't we back up Redis?"
    I'm not sure exactly what Redis is used for, but Nitter is read-only, so what's to back up? I expect that Redis is simply used for caching, so that content you've already seen via Nitter can be re-loaded faster. The `--save 60 1` argument tells Redis to save a snapshot every 60 seconds, so it's probably not a big deal to just back up Redis's data with your existing backup of `/var/data` (*you do backup your data, right?*)

## Serving

### Launch Nitter!

Launch the Nitter stack by running ```docker stack deploy nitter -c <path -to-docker-compose.yml>```, then browse to the URL you chose above, and you should be able to start viewing / searching Twitter privately and anonymously!

### Now what?

Now that you have a Nitter instance, you could try one of the following ideas:

:one: Setup RSS feeds for users you enjoy following, and read their tweets in your [RSS reader][miniflux]<br/>
:two: Setup RSS feeds for useful searches, and follow the search results in your [RSS reader][tiny-tiny-rss]<br/>
:three: Use a browser add-on like "[libredirect](https://addons.mozilla.org/en-US/firefox/addon/libredirect/)", to automatically redirect any links from twitter.com to your Nitter instance

## Summary

What have we achieved? We have our own instance of Nitter[^1], and we can anonymously and privately consume Twitter without being subject to advertising or tracking. We can even consume Twitter content via RSS, and no unhinged billionaires can lock us out of the API!

!!! summary "Summary"
    Created:

    * [X] Our own Nitter instance, safe from meddling :rocket: billionaires! 

[^1]: Since Nitter is private and read-only anyway, this recipe doesn't take into account any sort of authentication using [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/). If you wanted to protect your Nitter instance behind either Traefik Forward Auth or [Authelia][authelia], you'll just need to add the appropriate `traefik.http.routers.nitter.middlewares` label.

--8<-- "recipe-footer.md"
