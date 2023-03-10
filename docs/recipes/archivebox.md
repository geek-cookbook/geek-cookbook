---
title: Run Archivebox on Docker Swarm
description: Archivebox - bookmark manager for your self-hosted stack
recipe: Archivebox
---

# Archivebox

[ArchiveBox](https://github.com/ArchiveBox/ArchiveBox) is a self-hosted internet archiving solution to collect and save sites you wish to view offline.

![Archivebox Screenshot](../images/archivebox.png){ loading=lazy }

Features include:

- Uses standard formats such as HTML, JSON, PDF, PNG
- Ability to autosave to [archive.org](https://github.com/ArchiveBox/ArchiveBox/wiki/Configuration#submit_archive_dot_org)
- Supports Scheduled importing
- Supports Realtime importing

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

First, we create a directory to hold the data which archivebox will store:

```bash
mkdir /var/data/archivebox
mkdir /var/data/config/archivebox
cd /var/data/config/archivebox
```

### Create docker-compose.yml

Create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml
version: '3.2'

services:
    archivebox:
        image: archivebox/archivebox
        command: server --quick-init 0.0.0.0:8000
        ports:
            - 8000:8000
        networks:
          - traefik_public
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=Pacific/Auckland
            - USE_COLOR=True
            - SHOW_PROGRESS=False
        deploy:
          labels:
            # traefik common
            - traefik.enable=true
            - traefik.docker.network=traefik_public
            # traefikv1
            - traefik.frontend.rule=Host:archive.example.com
            - traefik.port=8000     
            # traefikv2
            - "traefik.http.routers.archive.rule=Host(`archive.example.com`)"
            - "traefik.http.routers.archive.entrypoints=https"
            - "traefik.http.services.archive.loadbalancer.server.port=8000" 
        volumes:
          - /var/data/archivebox:/data


networks:
  traefik_public:
    external: true
```

### Initalizing Archivebox

Once you have created the docker file you will need to run the following command to configure archivebox and create an account.
`docker run -v /var/data/archivebox:/data -it archivebox/archivebox init --setup`

## Serving

### Launch Archivebox!

Launch the Archivebox stack by running ```docker stack deploy archivebox -c <path -to-docker-compose.yml>```

[^1]: The inclusion of Archivebox was due to the efforts of @bencey in Discord (Thanks Ben!)

--8<-- "recipe-footer.md"
