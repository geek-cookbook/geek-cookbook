!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipies/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# LazyLibrarian

[LazyLibrarian](https://github.com/DobyTang/LazyLibrarian) is a tool to follow authors and grab metadata for all your digital reading needs. It uses a combination of Goodreads Librarything and optionally GoogleBooks as sources for author info and book info. Features include:

* Find authors and add them to the database
* List all books of an author and mark ebooks or audiobooks as 'wanted'.
* When processing the downloaded books it will save a cover picture (if available) and save all metadata into metadata.opf next to the bookfile (calibre compatible format)
* AutoAdd feature for book management tools like Calibre which must have books in flattened directory structure, or use calibre to import your books into an existing calibre library
* LazyLibrarian can also be used to search for and download magazines, and monitor for new issues

![Lazy Librarian Screenshot](../../images/lazylibrarian.png)

## Inclusion into AutoPirate

To include LazyLibrarian in your [AutoPirate](/recipies/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```
lazylibrarian:
  image: linuxserver/lazylibrarian:latest
  env_file : /var/data/config/autopirate/lazylibrarian.env
  volumes:
   - /var/data/autopirate/lazylibrarian:/config
   - /var/data/media:/media
  networks:
  - internal

lazylibrarian_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/lazylibrarian.env
  dns_search: myswarm.example.com  
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:lazylibrarian.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://lazylibrarian:5299
    -redirect-url=https://lazylibrarian.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt

calibre-server:
  image: regueiro/calibre-server
  volumes:
   - /var/data/media/Ebooks/calibre/:/opt/calibre/library
  networks:
  - internal    

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
* [Mylar](https://github.com/evilhero/mylar)
* Lazy Librarian (this page)
* [Headphones](https://github.com/rembo10/headphones)
* [NZBHydra](/recipies/autopirate/nzbhydra/)
* [Ombi](/recipies/autopirate/ombi/)
* [Jackett](/recipies/autopirate/jackett/)
* [End](/recipies/autopirate/end/) (launch the stack)


## Chef's Notes 📓

1. The calibre-server container co-exists within the Lazy Librarian (LL) containers so that LL can automatically add a book to Calibre using the calibre-server interface. The calibre library can then be properly viewed using the [calibre-web](/recipies/calibre-web) recipe.
2. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
