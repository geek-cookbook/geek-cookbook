!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipies/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# RTorrent / ruTorrent

[RTorrent](http://rakshasa.github.io/rtorrent) is a popular CLI-based bittorrent client, and [ruTorrent](https://github.com/Novik/ruTorrent) is a powerful web interface for rtorrent.

![Rtorrent Screenshot](../../images/rtorrent.png)

## Choose incoming port

When using a torrent client from behind NAT (_which swarm, by nature, is_), you typically need to set a static port for inbound torrent communications. In the example below, I've set the port to 36258. You'll need to configure /var/data/autopirate/rtorrent/rtorrent/rtorrent.rc with the equivalent port.

## Inclusion into AutoPirate

To include ruTorrent in your [AutoPirate](/recipies/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
rtorrent:
  image: linuxserver/rutorrent
  env_file : /var/data/config/autopirate/rtorrent.env
  ports:
   - 36258:36258
  volumes:
   - /var/data/media/:/media
   - /var/data/autopirate/rtorrent:/config
  networks:
  - internal

rtorrent_proxy:
  image: skippy/oauth2_proxy
  env_file : /var/data/config/autopirate/rtorrent.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:rtorrent.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://rtorrent:80
    -redirect-url=https://rtorrent.example.com
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
* RTorrent (this page)
* [Sonarr](/recipies/autopirate/sonarr/)
* [Radarr](/recipies/autopirate/radarr/)
* [Mylar](/recipies/autopirate/mylar/)
* [Lazy Librarian](/recipies/autopirate/lazylibrarian/)
* [Headphones](/recipies/autopirate/headphones/)
* [Lidarr](/recipies/autopirate/lidarr/) 
* [NZBHydra](/recipies/autopirate/nzbhydra/)
* [NZBHydra2](/recipies/autopirate/nzbhydra2/)
* [Ombi](/recipies/autopirate/ombi/)
* [Jackett](/recipies/autopirate/jackett/)
* [End](/recipies/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
