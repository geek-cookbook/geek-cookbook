hero: A recipe for a sexy view of your Docker Swarm

# Portainer

[Portainer](https://portainer.io/) is a lightweight sexy UI for visualizing your docker environment. It also happens to integrate well with Docker Swarm clusters, which makes it a great fit for our stack.

![Portainer Screenshot](../images/portainer.png)

This is a "lightweight" recipe, because Portainer is so "lightweight". But it **is** shiny...

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

Create a folder to store portainer's persistent data:

```
mkdir /var/data/portainer
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [sponsors](https://github.com/sponsors/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that sponsors can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: "3"

services:
  app:
    image: portainer/portainer
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/data/portainer:/data
    networks:
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:portainer.funkypenguin.co.nz
        - traefik.port=9000
      placement:
        constraints: [node.role == manager]
    command: -H unix:///var/run/docker.sock

networks:
  traefik_public:
    external: true
```

## Serving

### Launch Portainer stack

Launch the Portainer stack by running ```docker stack deploy portainer -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. You'll be prompted to set your admin user/password.

## Chef's Notes 📓

1. I wanted to use oauth2_proxy to provide an additional layer of security for Portainer, but the proxy seems to break the authentication mechanism, effectively making the stack **so** secure, that it can't be logged into!
