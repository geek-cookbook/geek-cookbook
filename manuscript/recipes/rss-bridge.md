# RSS Bridge


Do you hate having to waste time looking for a specific post. [RSS-Bridge](https://github.com/RSS-Bridge/rss-bridge) can convert the busiest parts of the web into nice structured plaintext to help quickly find exactly what you are looking for.

![RSS Screenshot](../images/rssbridge.png)


Features include

* Ability to generate RSS feeds for sites that do not have one.
* Can be used as a webserver or used as a CLI
* Supports multiple output formats such as 
    * Atom
    * HTML
    * JSON
    * Mrss
    * Plaintext

--8<-- "recipe-standard-ingredients.md"


## Preparation

### Setup data locations

First we create a directory to hold the data which RSS Bridge will serve:

```
mkdir /var/data/config/rssbridge
cd /var/data/config/rssbridge
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'
services:
  rss:
    image: rssbridge/rss-bridge:latest
    volumes:
      - /var/data/config/rssbridge:/config
    deploy:
      labels:
        # traefik common
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:rssbridge.example.com
        - traefik.port=80     

        # traefikv2
        - "traefik.http.routers.rssbridge.rule=Host(`rssbridge.example.com`)"
        - "traefik.http.services.rssbridge.loadbalancer.server.port=80" 
    networks:
      - traefik_public

networks:
  traefik_public:
    external: true
```

## Serving

### Launch RSS Bridge!

Launch the RSS Bridge stack by running ```docker stack deploy rssbridge -c <path -to-docker-compose.yml>```

[^1]: The inclusion of RSS Bridge was due to the efforts of Bencey in our [Discord server](http://chat.funkypenguin.co.nz). Thanks Ben!!
[^2]: This recipe goes well with an RSS reader such as [miniflux] 

--8<-- "recipe-footer.md"
