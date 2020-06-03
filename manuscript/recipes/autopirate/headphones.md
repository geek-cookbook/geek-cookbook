hero: AutoPirate - A fully-featured recipe to automate finding, downloading, and organising your media    

!!! warning
    This is not a complete recipe - it's a component of the [autopirate](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Headphones

[Headphones](https://github.com/rembo10/headphones) is an automated music downloader for NZB and Torrent, written in Python. It supports SABnzbd, NZBget, Transmission, Torrent, Deluge and Blackhole.

![Headphones Screenshot](../../images/headphones.png)

## Inclusion into AutoPirate

To include Headphones in your [AutoPirate](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
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
```

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/end/)** section:

* [SABnzbd](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/sabnzbd.md)
* [NZBGet](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/nzbget.md)
* [RTorrent](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/rtorrent/)
* [Sonarr](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/sonarr/)
* [Radarr](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/radarr/)
* [Mylar](https://github.com/evilhero/mylar)
* [Lazy Librarian](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/lazylibrarian/)
* Headphones (this page)
* [Lidarr](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/lidarr/)
* [NZBHydra](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/nzbhydra/)
* [NZBHydra2](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/nzbhydra2/)
* [Ombi](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/ombi/)
* [Jackett](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/jackett/)
* [Heimdall](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/heimdall/)
* [End](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/end/) (launch the stack)


## Chef's Notes 

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.