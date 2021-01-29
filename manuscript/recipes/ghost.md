hero: Ghost - A recipe for beautiful online publication.

# Ghost

[Ghost](https://ghost.org) is "a fully open source, hackable platform for building and running a modern online publication."

![](/images/ghost.png)

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

Create the location for the bind-mount of the application data, so that it's persistent:

```
mkdir -p /var/data/ghost
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  ghost:
    image: ghost:1-alpine
    volumes:
     - /etc/localtime:/etc/localtime:ro
     - /var/data/ghost/:/var/lib/ghost/content
    networks:
    - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:ghost.example.com
        - traefik.docker.network=traefik
        - traefik.port=2368

networks:
  traefik_public:
    external: true
```


## Serving

### Launch Ghost stack

Launch the Ghost stack by running ```docker stack deploy ghost -c <path -to-docker-compose.yml>```

Create your first administrative account at https://**YOUR-FQDN**/admin/

[^1]: A default using the SQlite database takes 548k of space

--8<-- "recipe-footer.md"