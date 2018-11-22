hero: AutoPirate - A fully-featured recipe to automate finding, downloading, and organising your media 📺 🎥 🎵 📖

!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Headphones

[Headphones](https://github.com/rembo10/headphones) is an automated music downloader for NZB and Torrent, written in Python. It supports SABnzbd, NZBget, Transmission, µTorrent, Deluge and Blackhole.

![Headphones Screenshot](../../images/headphones.png)

## Inclusion into AutoPirate

To include Headphones in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

````
headphones:
  image: linuxserver/headphones:latest
  env_file : /var/data/config/autopirate/headphones.env
  volumes:
   - /var/data/autopirate/headphones:/config
   - /var/data/media:/media
  networks:
  - internal

headphones_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/headphones.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:headphones.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://headphones:8181
    -redirect-url=https://headphones.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

* [SABnzbd](/recipes/autopirate/sabnzbd.md)
* [NZBGet](/recipes/autopirate/nzbget.md)
* [RTorrent](/recipes/autopirate/rtorrent/)
* [Sonarr](/recipes/autopirate/sonarr/)
* [Radarr](/recipes/autopirate/radarr/)
* [Mylar](https://github.com/evilhero/mylar)
* [Lazy Librarian](/recipes/autopirate/lazylibrarian/)
* Headphones (this page)
* [Lidarr](/recipes/autopirate/lidarr/)
* [NZBHydra](/recipes/autopirate/nzbhydra/)
* [NZBHydra2](/recipes/autopirate/nzbhydra2/)
* [Ombi](/recipes/autopirate/ombi/)
* [Jackett](/recipes/autopirate/jackett/)
* [Heimdall](/recipes/autopirate/heimdall/)
* [End](/recipes/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
