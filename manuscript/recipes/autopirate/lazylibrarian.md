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

To include LazyLibrarian in your [AutoPirate][autopirate] stack, include the following in your autopirate.yml stack definition file:

```yaml
lazylibrarian:
  image: linuxserver/lazylibrarian:latest
  env_file : /var/data/config/autopirate/lazylibrarian.env
  volumes:
   - /var/data/autopirate/lazylibrarian:/config
   - /var/data/media:/media
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:lazylibrarian.example.com
      - traefik.port=5299
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.lazylibrarian.rule=Host(`lazylibrarian.example.com`)"
      - "traefik.http.routers.lazylibrarian.entrypoints=https"
      - "traefik.http.services.lazylibrarian.loadbalancer.server.port=5299"
      - "traefik.http.routers.lazylibrarian.middlewares=forward-auth"

calibre-server:
  image: regueiro/calibre-server
  volumes:
   - /var/data/media/Ebooks/calibre/:/opt/calibre/library
  networks:
  - internal    

```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"

[^2]: The calibre-server container co-exists within the Lazy Librarian (LL) containers so that LL can automatically add a book to Calibre using the calibre-server interface. The calibre library can then be properly viewed using the [calibre-web](/recipes/calibre-web) recipe.