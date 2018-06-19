hero: Heroic Hero

# NAME

Intro

![NAME Screenshot](../images/name.jpg)

Details

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/wekan:

```
mkdir /var/data/wekan
cd /var/data/wekan
mkdir -p {wekan-db,wekan-db-dump}
```

### Prepare environment

Create wekan.env, and populate with the following variables
```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
MONGO_URL=mongodb://wekandb:27017/wekan
ROOT_URL=https://wekan.example.com
MAIL_URL=smtp://wekan@wekan.example.com:password@mail.example.com:587/
MAIL_FROM="Wekan <wekan@wekan.example.com>"
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:

  wekandb:
    image: mongo:3.2.15
    command: mongod --smallfiles --oplogSize 128
    networks:
      - internal
    volumes:
      - /var/data/wekan/wekan-db:/data/db
      - /var/data/wekan/wekan-db-dump:/dump

  proxy:
    image: a5huynh/oauth2_proxy
    env_file: /var/data/wekan/wekan.env
    networks:
      - traefik
      - internal
    deploy:
      labels:
        - traefik.frontend.rule=Host:wekan.example.com
        - traefik.docker.network=traefik
        - traefik.port=4180
    command: |
      -cookie-secure=false
      -upstream=http://wekan:80
      -redirect-url=https://wekan.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github

  wekan:
    image: wekanteam/wekan:latest
    networks:
      - internal
    env_file: /var/data/wekan/wekan.env

networks:
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.3.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch Wekan stack

Launch the Wekan stack by running ```docker stack deploy wekan -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

## Chef's Notes

1. If you wanted to expose the Wekan UI directly, you could remove the oauth2_proxy from the design, and move the traefik-related labels directly to the wekan container. You'd also need to add the traefik network to the wekan container.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
