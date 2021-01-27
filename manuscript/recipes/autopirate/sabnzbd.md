!!! warning
    This is not a complete recipe - it's a component of the [AutoPirate](/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# SABnzbd

## Introduction

SABnzbd is the workhorse of the stack. It takes .nzb files as input (_manually or from other [autopirate](/recipes/autopirate/) stack tools_), then connects to your chosen Usenet provider, downloads all the individual binaries referenced by the .nzb, and then tests/repairs/combines/uncompresses them all into the final result - media files.

![SABNZBD Screenshot](../../images/sabnzbd.png)

## Inclusion into AutoPirate

To include SABnzbd in your [AutoPirate](/recipes/autopirate/) stack
(_The only reason you **wouldn't** use SABnzbd, would be if you were using [NZBGet](/recipes/autopirate/nzbget.md) instead_), include the following in your autopirate.yml stack definition file:

--8<-- "premix-cta.md"

```yaml
sabnzbd:
  image: linuxserver/sabnzbd:latest
  env_file : /var/data/config/autopirate/sabnzbd.env  
  volumes:
    - /var/data/autopirate/sabnzbd:/config
    - /var/data/media:/media
    networks:
    - internal
  deploy:
    labels:
      # traefik
      - traefik.enable=true
      - traefik.docker.network=traefik_public

      # traefikv1
      - traefik.frontend.rule=Host:sabnzbd.example.com
      - traefik.port=8080
      - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
      - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
      - traefik.frontend.auth.forward.trustForwardHeader=true        

      # traefikv2
      - "traefik.http.routers.sabnzbd.rule=Host(`sabnzbd.example.com`)"
      - "traefik.http.routers.sabnzbd.entrypoints=https"
      - "traefik.http.services.sabnzbd.loadbalancer.server.port=8080"
      - "traefik.http.routers.sabnzbd.middlewares=forward-auth"
```

!!! warning "Important Note re hostname validation"

    (**Updated 10 June 2018**) : In SABnzbd [2.3.3](https://sabnzbd.org/wiki/extra/hostname-check.html), hostname verification was added as a mandatory check. SABnzbd will refuse inbound connections which weren't addressed to its own (_initially, autodetected_) hostname. This presents a problem within Docker Swarm, where container hostnames are random and disposable.

    You'll need to edit sabnzbd.ini (_only created after your first launch_), and **replace** the value in ```host_whitelist``` configuration (_it's comma-separated_) with the name of your service within the swarm definition, as well as your FQDN as accessed via traefik.

    For example, mine simply reads ```host_whitelist = sabnzbd.funkypenguin.co.nz, sabnzbd```

--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"