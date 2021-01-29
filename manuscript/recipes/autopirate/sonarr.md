!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.


# Sonarr

[Sonarr](https://sonarr.tv/) is a tool for finding, downloading and managing your TV series.

![Sonarr Screenshot](../../images/sonarr.png)

## Inclusion into AutoPirate

To include Sonarr in your [AutoPirate][autopirate] stack, include the following in your autopirate.yml stack definition file:

```yaml
sonarr:
  image: linuxserver/sonarr:latest
  env_file : /var/data/config/autopirate/sonarr.env
  volumes:
   - /var/data/autopirate/sonarr:/config
   - /var/data/media:/media
  networks:
  - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:sonarr.example.com
      - traefik.port=8989
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.sonarr.rule=Host(`sonarr.example.com`)"
      - "traefik.http.routers.sonarr.entrypoints=https"
      - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
      - "traefik.http.routers.sonarr.middlewares=forward-auth"
```

--8<-- "premix-cta.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"