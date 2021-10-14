# RSS Bridge


Do you hate having to access multiple sites to view specific content? [RSS-Bridge](https://github.com/RSS-Bridge/rss-bridge) can convert content from a wide variety of websites (*such as Reddit, Facebook, Twitter*) so that it can be viewed in a structured and consistent way, all from one place (Your feed reader)

![RSS-Bridge Screenshot](../images/rssbridge.png)

--8<-- "recipe-standard-ingredients.md"


## Preparation

### Setup data locations

First we create a directory to hold the data which RSS Bridge will serve:

```bash
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

### Deploy the bridge!

Launch the RSS Bridge stack by running ```docker stack deploy rssbridge -c <path -to-docker-compose.yml>```

[^1]: The inclusion of RSS Bridge was due to the efforts of @bencey in [Discord](http://chat.funkypenguin.co.nz) (Thanks Ben!)
[^2]: This delicious recipe is well-paired with an RSS reader such as [Miniflux][miniflux]

--8<-- "recipe-footer.md"
