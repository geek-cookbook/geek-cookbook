!!! warning
This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# NZBHydra 2

[NZBHydra 2](https://github.com/theotherp/nzbhydra2) is a meta search for NZB indexers. It provides easy access to a number of raw and newznab based indexers. You can search all your indexers from one place and use it as an indexer source for tools like Sonarr, Radarr or CouchPotato.

![NZBHydra Screenshot](../../images/nzbhydra2.png)

Features include:

- Searches Anizb, BinSearch, NZBIndex and any newznab compatible indexers. Merges all results, filters them by a number of configurable restrictions, recognizes duplicates and returns them all in one place
- Add results to [NZBGet][nzbget] or [SABnzbd][sabnzbd]
- Support for all relevant media IDs (IMDB, TMDB, TVDB, TVRage, TVMaze) and conversion between them
- Query generation, meaning a query will be generated if only a media ID is provided in the search and the indexer doesn't support the ID or if no results were found
- Compatible with [Sonarr][sonarr], [Radarr][radarr], [NZBGet][nzbget], [SABnzbd][sabnzbd], nzb360, CouchPotato, [Mylar][mylar], [Lazy Librarian][lazylibrarian], Sick Beard, [Jackett][jackett], Watcher, etc.
- Search and download history and extensive stats. E.g. indexer response times, download shares, NZB age, etc.
- Authentication and multi-user support
- Automatic update of NZB download status by querying configured downloaders
- RSS support with configurable cache times
- Torrent support (_Although I prefer [Jackett][jackett] for this_):
  - For GUI searches, allowing you to download torrents to a blackhole folder
  - A separate Torznab compatible endpoint for API requests, allowing you to merge multiple trackers
- Extensive configurability
- Migration of database and settings from v1

## Inclusion into AutoPirate

To include NZBHydra2 in your [AutoPirate][autopirate] stack, include the following in your autopirate.yml stack definition file:

```yaml
nzbhydra2:
  image: linuxserver/hydra2:latest
  env_file : /var/data/config/autopirate/nzbhydra2.env
  volumes:
   - /var/data/autopirate/nzbhydra2:/config
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:nzbhydra.example.com
      - traefik.port=5076
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.nzbhydra.rule=Host(`nzbhydra.example.com`)"
      - "traefik.http.routers.nzbhydra.entrypoints=https"
      - "traefik.http.services.nzbhydra.loadbalancer.server.port=5076"
      - "traefik.http.routers.nzbhydra.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"