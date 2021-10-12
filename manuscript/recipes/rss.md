# RSS Bridge

[RSS-Bridge](https://github.com/RSS-Bridge/rss-bridge) is a PHP project capable of generating RSS and Atom feeds for websites that don't have one. It can be used on webservers or as a stand-alone application in CLI mode. You can deploy the service in different ways. Such as installing using PHP, Or you can setup using the Docker [Image](https://hub.docker.com/r/rssbridge/rss-bridge).

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

--8<-- "recipe-footer.md"
