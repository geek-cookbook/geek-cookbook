!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipies/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.


# NZBHydra

[NZBHydra](https://github.com/theotherp/nzbhydra) is a meta search for NZB indexers. It provides easy access to a number of raw and newznab based indexers. You can search all your indexers from one place and use it as indexer source for tools like Sonarr or CouchPotato. Features include:

* Search by IMDB, TMDB, TVDB, TVRage and TVMaze ID (including season and episode) and filter by age and size. If an ID is not supported by an indexer it is attempted to be converted (e.g. TMDB to IMDB)
* Query generation, meaning when you search for a movie using e.g. an IMDB ID a query will be generated for raw indexers. Searching for a series season 1 episode 2 will also generate queries for raw indexers, like s01e02 and 1x02
* Grouping of results with the same title and of duplicate results, accounting for result posting time, size, group and poster. By default only one of the duplicates is shown. You can provide an indexer score to influence which one that might be
* Compatible with Sonarr, CP, NZB 360, SickBeard, Mylar and Lazy Librarian (and others)
* Statistics on indexers (average response time, share of results, access errors), searches and downloads per time of day and day of week, NZB download history and search history (both via internal GUI and API)

![NZBHydra Screenshot](../../images/nzbhydra.png)

## Inclusion into AutoPirate

To include NZBHydra in your [AutoPirate](/recipies/autopirate/) stack, include the following in your autopirate.yml stack definition file:

````
nzbhydra:
  image: linuxserver/hydra:latest
  env_file : /var/data/config/autopirate/nzbhydra.env
  volumes:
   - /var/data/autopirate/nzbhydra:/config
  networks:
  - internal

nzbhydra_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/nzbhydra.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:nzbhydra.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://nzbhydra:5075
    -redirect-url=https://nzbhydra.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipies/autopirate/end/)** section:

* [SABnzbd](/recipies/autopirate/sabnzbd.md)
* [NZBGet](/recipies/autopirate/nzbget.md)
* [RTorrent](/recipies/autopirate/rtorrent/)
* [Sonarr](/recipies/autopirate/sonarr/)
* [Radarr](/recipies/autopirate/radarr/)
* [Mylar](/recipies/autopirate/mylar/)
* [Lazy Librarian](/recipies/autopirate/lazylibrarian/)
* [Headphones](/recipies/autopirate/headphones/)
* [Lidarr](/recipies/autopirate/lidarr/)
* NZBHydra (this page)
* [NZBHydra2](/recipies/autopirate/nzbhydra2/)
* [Ombi](/recipies/autopirate/ombi/)
* [Jackett](/recipies/autopirate/jackett/)
* [Heimdall](/recipies/autopirate/heimdall/)
* [End](/recipies/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
