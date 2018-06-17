hero: Heroic Hero

# Munin

Intro

![NAME Screenshot](../images/name.jpg)

Details

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/munin:

```
mkdir /var/data/munin
cd /var/data/munin
mkdir -p {log,lib,run,cache}
```

### Prepare environment

Create /var/data/config/munin/munin.env, and populate with the following variables
```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=

MUNIN_USER=odin
MUNIN_PASSWORD=lokiisadopted
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=smtp-username
SMTP_PASSWORD=smtp-password
SMTP_USE_TLS=false
SMTP_ALWAYS_SEND=false
SMTP_MESSAGE='[${var:group};${var:host}] -> ${var:graph_title} -> warnings: ${loop<,>:wfields  ${var:label}=${var:value}} / criticals: ${loop<,>:cfields  ${var:label}=${var:value}}'
ALERT_RECIPIENT=monitoring@example.com
ALERT_SENDER=alerts@example.com
NODES="node1:10.20.30.1 node2:10.20.30.22 node3:10.20.30.23"
SNMP_NODES="router1:10.0.0.254:9999"
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:

  munin:
    image: funkypenguin/munin-server
    env_file: /var/data/config/munin/munin.env    
    networks:
      - internal
    volumes:
      - /var/data/munin/log:/var/log/munin
      - /var/data/munin/lib:/var/lib/munin
      - /var/data/munin/run:/var/run/munin
      - /var/data/munin/cache:/var/cache/munin  

  proxy:
    image: zappi/oauth2_proxy
    env_file: /var/data/config/munin/munin.env
    networks:
      - traefik
      - internal
    deploy:
      labels:
        - traefik.frontend.rule=Host:munin.example.com
        - traefik.docker.network=traefik
        - traefik.port=4180
    command: |
      -cookie-secure=false
      -upstream=http://munin:8080
      -redirect-url=https://munin.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github

networks:
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.20.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.

## Node

```
docker stop munin-node
docker rm munin-node
docker run -d --name munin-node --restart=always \
  --privileged --net=host \
  -v /:/rootfs:ro \
  -v /sys:/sys:ro \
  -e ALLOW="cidr_allow 0.0.0.0/0" \
  -p 4949:4949 \
  --restart=always \
  funkypenguin/munin-node
```




## Serving

### Launch Wekan stack

Launch the Wekan stack by running ```docker stack deploy wekan -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

## Chef's Notes

1. If you wanted to expose the Wekan UI directly, you could remove the oauth2_proxy from the design, and move the traefik-related labels directly to the wekan container. You'd also need to add the traefik network to the wekan container.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
