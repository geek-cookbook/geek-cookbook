!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# RTorrent / ruTorrent

[RTorrent](http://rakshasa.github.io/rtorrent) is a popular CLI-based bittorrent client, and [ruTorrent](https://github.com/Novik/ruTorrent) is a powerful web interface for rtorrent.

![Rtorrent Screenshot](../../images/rtorrent.png)

## Choose incoming port

When using a torrent client from behind NAT (_which swarm, by nature, is_), you typically need to set a static port for inbound torrent communications. In the example below, I've set the port to 36258. You'll need to configure /var/data/autopirate/rtorrent/rtorrent/rtorrent.rc with the equivalent port.

## Inclusion into AutoPirate

To include ruTorrent in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

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

--8<-- "premix-cta.md"

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

* [SABnzbd](/recipes/autopirate/sabnzbd.md)
* [NZBGet](/recipes/autopirate/nzbget.md)
* RTorrent (this page)
* [Sonarr](/recipes/autopirate/sonarr/)
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

[^1]: In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

--8<-- "recipe-footer.md"