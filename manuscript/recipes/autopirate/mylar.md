!!! warning
    This is not a complete recipe - it's a component of the [autopirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# Mylar

[Mylar](https://github.com/mylar3/mylar3) is a tool for downloading and managing digital comic books.

![Mylar Screenshot](../../images/mylar.jpg)

## Inclusion into AutoPirate

To include Mylar in your [AutoPirate](/recipes/autopirate/) stack, include the following in your autopirate.yml stack definition file:

```yaml
mylar:
  image: linuxserver/mylar3:latest
  env_file : /var/data/config/autopirate/mylar.env
  volumes:
   - /var/data/autopirate/mylar:/config
   - /var/data/media:/media
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:mylar.example.com
      - traefik.port=8090
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.mylar.rule=Host(`mylar.example.com`)"
      - "traefik.http.routers.mylar.entrypoints=https"
      - "traefik.http.services.mylar.loadbalancer.server.port=8090"
      - "traefik.http.routers.mylar.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"

[^2]. If you intend to configure Mylar to perform its own NZB searches and push the hits to a downloader such as SABnzbd, then in addition to configuring the connection to SAB with host, port and api key, you will need to set the parameter `host_return` parameter to the fully qualified Mylar address (e.g. `http://mylar:8090`).