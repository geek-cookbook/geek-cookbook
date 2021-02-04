# Emby

[Emby](https://emby.media/) (_think "M.B." or "Media Browser"_) is best described as "_like [Plex](/recipes/plex/) but different_" 😁 - It's a bit geekier and less polished than Plex, but it allows for more flexibility and customization.

![Emby Screenshot](../images/emby.png)

I've started experimenting with Emby as an alternative to Plex, because of the advanced [parental controls](https://github.com/MediaBrowser/Wiki/wiki/Parental-Controls) it offers. Based on my experimentation thus far, I have a "**kid-safe**" profile which automatically logs in, and only displays kid-safe content, based on ratings.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need a location to store Emby's library data, config files, logs and temporary transcoding space, so create /var/data/emby, and make sure it's owned by the user and group who also own your media data.

```
mkdir /var/data/emby
```

### Prepare environment

Create emby.env, and populate with PUID/GUID for the user who owns the /var/data/emby directory (_above_) and your actual media content (_in this example, the media content is at **/srv/data**_)

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
  emby:
    image: emby/emby-server
    env_file: /var/data/config/emby/emby.env
    volumes:
      - /var/data/emby/emby:/config
      - /srv/data/:/data
    deploy:
      labels:
        - traefik.frontend.rule=Host:emby.example.com
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
        - subnet: 172.16.17.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Emby stack

Launch the stack by running ```docker stack deploy emby -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, and complete the wizard-based setup to complete deploying your Emby.

[^1]: I didn't use an [oauth2_proxy](/reference/oauth_proxy/) for this stack, because it would interfere with mobile client support.
[^2]: Got an NVIDIA GPU? See [this blog post](https://www.funkypenguin.co.nz/note/gpu-transcoding-with-emby-plex-using-docker-nvidia/) re how to use your GPU to transcode your media!
[^3]: We don't bother exposing the HTTPS port for Emby, since [Traefik](/ha-docker-swarm/traefik/) is doing the SSL termination for us already.

--8<-- "recipe-footer.md"