!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Mylar

[Mylar](https://github.com/mylar3/mylar3) is a tool for downloading and managing digital comic books.

![Mylar Screenshot](../../images/mylar.jpg)

## Inclusion into AutoPirate

To include Mylar in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

````
mylar:
  image: linuxserver/mylar3:latest
  env_file : /var/data/config/autopirate/mylar.env
  volumes:
   - /var/data/autopirate/mylar:/config
   - /var/data/media:/media
  networks:
  - internal

mylar_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/mylar.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:mylar.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://mylar:8090
    -redirect-url=https://mylar.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
    I share (_with my [sponsors](https://github.com/sponsors/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that sponsors can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

* [SABnzbd](/recipes/autopirate/sabnzbd.md)
* [NZBGet](/recipes/autopirate/nzbget.md)
* [RTorrent](/recipes/autopirate/rtorrent/)
* [Sonarr](/recipes/autopirate/sonarr/)
* [Radarr](/recipes/autopirate/radarr/)
* Mylar (this page)
* [Lazy Librarian](/recipes/autopirate/lazylibrarian/)
* [Headphones](/recipes/autopirate/headphones)
* [Lidarr](/recipes/autopirate/lidarr/)
* [NZBHydra](/recipes/autopirate/nzbhydra/)
* [NZBHydra2](/recipes/autopirate/nzbhydra2/)
* [Ombi](/recipes/autopirate/ombi/)
* [Jackett](/recipes/autopirate/jackett/)
* [Heimdall](/recipes/autopirate/heimdall/)
* [End](/recipes/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

2. If you intend to configure Mylar to perform its own NZB searches and push the hits to a downloader such as SABnzbd, then in addition to configuring the connection to SAB with host, port and api key, you will need to set the parameter `host_return` parameter to the fully qualified Mylar address (e.g. `http://mylar:8090`).

    This will provide the link to the downloader necessary to initiate the download.  This parameter is not presented in the user interface so the config file (`$MYLAR_HOME/config.ini`) will need to be manually updated.  The parameter can be found under the [Interface] section of the file. ([Details](https://github.com/evilhero/mylar/issues/2242))