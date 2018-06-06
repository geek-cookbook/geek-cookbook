!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipies/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Jackett

[Jackett](https://github.com/Jackett/Jackett) works as a proxy server: it translates queries from apps (Sonarr, Radarr, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software.

This allows for getting recent uploads (like RSS) and performing searches. Jackett is a single repository of maintained indexer scraping & translation logic - removing the burden from other apps.

![Jackett Screenshot](../../images/jackett.png)

## Inclusion into AutoPirate

To include Jackett in your [AutoPirate](/recipies/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
jackett:
  image: linuxserver/jackett:latest
  env_file : /var/data/config/autopirate/jackett.env
  volumes:
   - /var/data/autopirate/jackett:/config
  networks:
  - internal

jackett_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/jackett.env
  dns_search: myswarm.example.com  
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:jackett.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://jackett:9117
    -redirect-url=https://jackett.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt

```

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipies/autopirate/end/)** section:

* [SABnzbd](/recipies/autopirate/sabnzbd.md)
* [NZBGet](/recipies/autopirate/nzbget.md)
* [RTorrent](/recipies/autopirate/rtorrent/)
* [Sonarr](/recipies/autopirate/sonarr/)
* [Radarr](/recipies/autopirate/radarr/)
* [Mylar](/recipies/autopirate/mylarr/)
* [Lazy Librarian](/recipies/autopirate/lazylibrarian/)
* [Headphones](/recipies/autopirate/headphones/)
* [NZBHydra](/recipies/autopirate/nzbhydra/)
* [Ombi](/recipies/autopirate/ombi/)
* Jackett (this page)
* [End](/recipies/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
