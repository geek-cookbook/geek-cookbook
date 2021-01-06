!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# LazyLibrarian

[LazyLibrarian](https://github.com/DobyTang/LazyLibrarian) is a tool to follow authors and grab metadata for all your digital reading needs. It uses a combination of Goodreads Librarything and optionally GoogleBooks as sources for author info and book info. Features include:

* Find authors and add them to the database
* List all books of an author and mark ebooks or audiobooks as 'wanted'.
* When processing the downloaded books it will save a cover picture (if available) and save all metadata into metadata.opf next to the bookfile (calibre compatible format)
* AutoAdd feature for book management tools like Calibre which must have books in flattened directory structure, or use calibre to import your books into an existing calibre library
* LazyLibrarian can also be used to search for and download magazines, and monitor for new issues

![Lazy Librarian Screenshot](../../images/lazylibrarian.png)

## Inclusion into AutoPirate

To include LazyLibrarian in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

````
lazylibrarian:
  image: linuxserver/lazylibrarian:latest
  env_file : /var/data/config/autopirate/lazylibrarian.env
  volumes:
   - /var/data/autopirate/lazylibrarian:/config
   - /var/data/media:/media
  networks:
  - internal

lazylibrarian_proxy:
  image: a5huynh/oauth2_proxy
  env_file : /var/data/config/autopirate/lazylibrarian.env
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

````

--8<-- "premix-cta.md"

## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

* [SABnzbd](/recipes/autopirate/sabnzbd.md)
* [NZBGet](/recipes/autopirate/nzbget.md)
* [RTorrent](/recipes/autopirate/rtorrent/)
* [Sonarr](/recipes/autopirate/sonarr/)
* [Radarr](/recipes/autopirate/radarr/)
* [Mylar](https://github.com/evilhero/mylar)
* Lazy Librarian (this page)
* [Headphones](/recipes/autopirate/headphones)
* [Lidarr](/recipes/autopirate/lidarr/)
* [NZBHydra](/recipes/autopirate/nzbhydra/)
* [NZBHydra2](/recipes/autopirate/nzbhydra2/)
* [Ombi](/recipes/autopirate/ombi/)
* [Jackett](/recipes/autopirate/jackett/)
* [Heimdall](/recipes/autopirate/heimdall/)
* [End](/recipes/autopirate/end/) (launch the stack)

## Chef's Notes 📓

[^1]: In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.
[^2]: The calibre-server container co-exists within the Lazy Librarian (LL) containers so that LL can automatically add a book to Calibre using the calibre-server interface. The calibre library can then be properly viewed using the [calibre-web](/recipes/calibre-web) recipe.

--8<-- "recipe-footer.md"