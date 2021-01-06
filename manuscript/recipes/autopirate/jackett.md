!!! warning
This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Jackett

[Jackett](https://github.com/Jackett/Jackett) works as a proxy server: it translates queries from apps (Sonarr, Radarr, Mylar, etc) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software.

This allows for getting recent uploads (like RSS) and performing searches. Jackett is a single repository of maintained indexer scraping & translation logic - removing the burden from other apps.

![Jackett Screenshot](../../images/jackett.png)

## Inclusion into AutoPirate

To include Jackett in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
jackett:
  image: linuxserver/jackett:latest
  env_file : /var/data/config/autopirate/jackett.env
  volumes:
   - /var/data/autopirate/jackett:/config
  networks:
  - internal

jackett_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/jackett.env
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

--8<-- "premix-cta.md"

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

- [SABnzbd](/recipes/autopirate/sabnzbd.md)
- [NZBGet](/recipes/autopirate/nzbget.md)
- [RTorrent](/recipes/autopirate/rtorrent/)
- [Sonarr](/recipes/autopirate/sonarr/)
- [Radarr](/recipes/autopirate/radarr/)
- [Mylar](/recipes/autopirate/mylar/)
- [Lazy Librarian](/recipes/autopirate/lazylibrarian/)
- [Headphones](/recipes/autopirate/headphones)
- [Lidarr](/recipes/autopirate/lidarr/)
- [NZBHydra](/recipes/autopirate/nzbhydra/)
- [NZBHydra2](/recipes/autopirate/nzbhydra2/)
- [Ombi](/recipes/autopirate/ombi/)
- Jackett (this page)
- [Heimdall](/recipes/autopirate/heimdall/)
- [End](/recipes/autopirate/end/) (launch the stack)

[^1]: In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

--8<-- "recipe-footer.md"