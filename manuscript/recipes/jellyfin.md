# Jellyfin

[Jellyfin](https://jellyfin.org/) is best described as "_like [Emby](/recipes/emby) but really [FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software)_".

![Jellyfin Screenshot](../images/jellyfin.png)

If it looks very similar as Emby, is because it started as a fork of it, but it has evolve since them. For a complete explanation of the why, look [here](https://jellyfin.org/docs/general/about.html).

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need a location to store Jellyfin's library data, config files, logs and temporary transcoding space, so create ``/var/data/jellyfin``, and make sure it's owned by the user and group who also own your media data.

```
mkdir /var/data/jellyfin
```

Also if we want to avoid the cache to be part of the backup, we should create a location to map it on the runtime folder. It also has to be owned by the user and group who also own your media data.

```
mkdir /var/data/runtime/jellyfin
```

### Prepare environment

Create jellyfin.env, and populate with PUID/GUID for the user who owns the /var/data/jellyfin directory (_above_) and your actual media content (_in this example, the media content is at **/srv/data**_)

```
PUID=
GUID=
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3.0"

services:
  jellyfin:
    image: jellyfin/jellyfin
    env_file: /var/data/config/jellyfin/jellyfin.env
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/data/jellyfin:/config
      - /var/data/runtime/jellyfin:/cache
      - /var/data/jellyfin/jellyfin:/config
      - /srv/data/:/data
    deploy:
      labels:
        - traefik.frontend.rule=Host:jellyfin.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=8096
    networks:
        - traefik_public
        - internal
    ports:
      - 8096:8096

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.57.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Jellyfin stack

Launch the stack by running ```docker stack deploy jellyfin -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, and complete the wizard-based setup to complete deploying your Jellyfin.

[^1]: I didn't use an [oauth2_proxy](/reference/oauth_proxy/) for this stack, because it would interfere with mobile client support.
[^2]: Got an NVIDIA GPU? See [this blog post](https://www.funkypenguin.co.nz/note/gpu-transcoding-with-emby-plex-using-docker-nvidia/) re how to use your GPU to transcode your media!
[^3]: We don't bother exposing the HTTPS port for Jellyfin, since [Traefik](/ha-docker-swarm/traefik/) is doing the SSL termination for us already.

--8<-- "recipe-footer.md"