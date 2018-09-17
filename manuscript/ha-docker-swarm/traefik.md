# Traefik

The platforms we plan to run on our cloud are generally web-based, and each listening on their own unique TCP port. When a container in a swarm exposes a port, then connecting to **any** swarm member on that port will result in your request being forwarded to the appropriate host running the container. (_Docker calls this the swarm "[routing mesh](https://docs.docker.com/engine/swarm/ingress/)"_)

So we get a rudimentary load balancer built into swarm. We could stop there, just exposing a series of ports on our hosts, and making them HA using keepalived.

There are some gaps to this approach though:

- No consideration is given to HTTPS. Implementation would have to be done manually, per-container.
- No mechanism is provided for authentication outside of that which the container providers. We may not **want** to expose every interface on every container to the world, especially if we are playing with tools or containers whose quality and origin are unknown.

To deal with these gaps, we need a front-end load-balancer, and in this design, that role is provided by [Traefik](https://traefik.io/).

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)

## Preparation

### Prepare the host

The traefik container is aware of the __other__ docker containers in the swarm, because it has access to the docker socket at **/var/run/docker.sock**. This allows traefik to dynamically configure itself based on the labels found on containers in the swarm, which is hugely useful. To make this functionality work on our SELinux-enabled Atomic hosts, we need to add custom SELinux policy.

!!! tip
    The following is only necessary if you're using SELinux!

Run the following to build and activate policy to permit containers to access docker.sock:

```
mkdir ~/dockersock
cd ~/dockersock
curl -O https://raw.githubusercontent.com/dpw/\
selinux-dockersock/master/Makefile
curl -O https://raw.githubusercontent.com/dpw/\
selinux-dockersock/master/dockersock.te
make && semodule -i dockersock.pp
```

### Prepare traefik.toml

While it's possible to configure traefik via docker command arguments, I prefer to create a config file (traefik.toml). This allows me to change traefik's behaviour by simply changing the file, and keeps my docker config simple.

Create ```/var/data/traefik/```, and then create ```traefik.toml``` inside it as follows:

```
checkNewVersion = true
defaultEntryPoints = ["http", "https"]

# This section enable LetsEncrypt automatic certificate generation / renewal
[acme]
email = "<your LetsEncrypt email address>"
storage = "acme.json" # or "traefik/acme/account" if using KV store
entryPoint = "https"
acmeLogging = true
onDemand = true
OnHostRule = true

[[acme.domains]]
  main = "<your primary domain>"

# Redirect all HTTP to HTTPS (why wouldn't you?)
[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
      entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]

[web]
address = ":8080"
watch = true

[docker]
endpoint = "tcp://127.0.0.1:2375"
domain = "<your primary domain>"
watch = true
swarmmode = true
```


### Prepare the docker service config

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


Create /var/data/config/traefik/docker-compose.yml as follows:

```
version: "3"

services:
  traefik:
    image: traefik
    command: --web --docker --docker.swarmmode --docker.watch --docker.domain=funkypenguin.co.nz --logLevel=DEBUG
    ports:
      - target: 80
        published: 80
        protocol: tcp
        mode: host
      - target: 443
        published: 443
        protocol: tcp
        mode: host
      - target: 8080
        published: 8080
        protocol: tcp
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/data/traefik/traefik.toml:/traefik.toml:ro
      - /var/data/traefik/acme.json:/acme.json
    labels:
      - "traefik.enable=false"
    networks:
      - public
    deploy:
      mode: global
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure

networks:
  public:
    driver: overlay
    ipam:
      driver: default
      config:
      - subnet: 10.1.0.0/24
```

Docker won't start an image with a bind-mount to a non-existent file, so prepare an empty acme.json (_with the appropriate permissions_) by running:

```
touch /var/data/traefik/acme.json
chmod 600 /var/data/traefik/acme.json
```

Traefik will populate acme.json itself when it runs, but it needs to exist before the container will start (_Chicken, meet egg._)

### Launch

Deploy traefik with ```docker stack deploy traefik -c /var/data/traefik/docker-compose.yml```

Confirm traefik is running with ```docker stack ps traefik```

## Serving

You now have:

1. Frontend proxy which will dynamically configure itself for new backend containers
2. Automatic SSL support for all proxied resources


## Chef's Notes

Additional features I'd like to see in this recipe are:

1. Include documentation of oauth2_proxy container for protecting individual backends
2. Traefik webUI is available via HTTPS, protected with oauth_proxy
3. Pending a feature in docker-swarm to avoid NAT on routing-mesh-delivered traffic, update the design

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
