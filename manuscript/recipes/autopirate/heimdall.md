!!! warning
    This is not a complete recipe - it's a component of the [autopirate](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Heimdall

[Heimdall Application Dashboard](https://heimdall.site/) is a dashboard for all your web applications. It doesn't need to be limited to applications though, you can add links to anything you like.

Heimdall is an elegant solution to organise all your web applications. It’s dedicated to this purpose so you won’t lose your links in a sea of bookmarks.

Heimdall provides a single URL to manage access to all of your autopirate tools, and includes "enhanced" (_i.e., display stats within Heimdall without launching the app_) access to [NZBGet](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/nzbget.md), [SABnzbd](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/sabnzbd/), and friends.

![Heimdall Screenshot](../../images/heimdall.jpg)

## Inclusion into AutoPirate

To include Heimdall in your [AutoPirate](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
  heimdall:
    image: linuxserver/heimdall:latest
    env_file: /var/data/config/autopirate/heimdall.env
    volumes:
      - /etc/localtime:/etc/localtime:ro      
      - /var/data/heimdall:/config
    networks:
      - internal

  heimdall_proxy:
    image: funkypenguin/oauth2_proxy:latest
    env_file : /var/data/config/autopirate/heimdall.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:heimdall.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=4180
    volumes:
      - /etc/localtime:/etc/localtime:ro  
      - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
    command: |
      -cookie-secure=false
      -upstream=http://heimdall:80
      -redirect-url=https://heimdall.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt



```

!!! tip
    I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/end/)** section:

* [SABnzbd](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/sabnzbd.md)
* [NZBGet](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/nzbget.md)
* [RTorrent](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/rtorrent/)
* [Sonarr](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/sonarr/)
* [Radarr](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/radarr/)
* [Mylar](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/mylarr/)
* [Lazy Librarian](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/lazylibrarian/)
* [Headphones](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/headphones)
* [Lidarr](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/lidarr/)
* [NZBHydra](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/nzbhydra/)
* [NZBHydra2](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/nzbhydra2/)
* [Ombi](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/ombi/)
* [Jackett](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/jackett/)
* Heimdall (this page)
* [End](https://geek-cookbook.funkypenguin.co.nz/)recipes/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.
2. The inclusion of Heimdall was due to the efforts of @gkoerk in our [Discord server](http://chat.funkypenguin.co.nz). Thanks gkoerk!