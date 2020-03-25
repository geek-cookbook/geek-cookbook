!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.


# Sonarr

[Sonarr](https://sonarr.tv/) is a tool for finding, downloading and managing your TV series.

![Sonarr Screenshot](../../images/sonarr.png)

!!! tip "Sponsored Project"
    Sonarr is one of my [sponsored projects](/sponsored-projects/) - a project I financially support on a regular basis because of its utility to me. I forget it's there until I (reliably) receive an email with new and exciting updates 😁

## Inclusion into AutoPirate

To include Sonarr in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
sonarr:
  image: linuxserver/sonarr:latest
  env_file : /var/data/config/autopirate/sonarr.env
  volumes:
   - /var/data/autopirate/sonarr:/config
   - /var/data/media:/media
  networks:
  - internal

sonarr_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/sonarr.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:sonarr.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://sonarr:8989
    -redirect-url=https://sonarr.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
```

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

* [SABnzbd](/recipes/autopirate/sabnzbd.md)
* [NZBGet](/recipes/autopirate/nzbget.md)
* [RTorrent](/recipes/autopirate/rtorrent/)
* Sonarr (this page)
* [Radarr](/recipes/autopirate/radarr/)
* [Mylar](/recipes/autopirate/mylar/)
* [Lazy Librarian](/recipes/autopirate/lazylibrarian/)
* [Headphones](/recipes/autopirate/headphones/)
* [Lidarr](/recipes/autopirate/lidarr/)
* [NZBHydra](/recipes/autopirate/nzbhydra/)
* [NZBHydra2](/recipes/autopirate/nzbhydra2/)
* [Ombi](/recipes/autopirate/ombi/)
* [Jackett](/recipes/autopirate/jackett/)
* [Heimdall](/recipes/autopirate/heimdall/)
* [End](/recipes/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

### Tip your waiter (support me) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 

### Your comments? 
