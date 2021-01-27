# Traefik

The platforms we plan to run on our cloud are generally web-based, and each listening on their own unique TCP port. When a container in a swarm exposes a port, then connecting to **any** swarm member on that port will result in your request being forwarded to the appropriate host running the container. (_Docker calls this the swarm "[routing mesh](https://docs.docker.com/engine/swarm/ingress/)"_)

So we get a rudimentary load balancer built into swarm. We could stop there, just exposing a series of ports on our hosts, and making them HA using keepalived.

There are some gaps to this approach though:

- No consideration is given to HTTPS. Implementation would have to be done manually, per-container.
- No mechanism is provided for authentication outside of that which the container providers. We may not **want** to expose every interface on every container to the world, especially if we are playing with tools or containers whose quality and origin are unknown.

To deal with these gaps, we need a front-end load-balancer, and in this design, that role is provided by [Traefik](https://traefik.io/).

![Traefik Screenshot](../images/traefik.png)

!!! tip
    In 2021, this recipe was updated for Traefik v2. There's really no reason to be using Traefikv1 anymore ;)

## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
    * [X] [Traefik](/ha-docker-swarm/traefik) configured per design
    * [X] DNS entry for the hostname you intend to use (*or a wildcard*), pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP

    New:
    
    * [ ] Access to update your DNS records for manual/automated [LetsEncrypt](https://letsencrypt.org/docs/challenge-types/) DNS-01 validation, or ingress HTTP/HTTPS for HTTP-01 validation
  
## Preparation

### Prepare traefik.toml

While it's possible to configure traefik via docker command arguments, I prefer to create a config file (`traefik.toml`). This allows me to change traefik's behaviour by simply changing the file, and keeps my docker config simple.

Create `/var/data/traefikv2/traefik.toml` as follows:

```
[global]
  checkNewVersion = true

# Enable the Dashboard
[api]
  dashboard = true

# Write out Traefik logs
[log]
  level = "INFO"
  filePath = "/traefik.log"

[entryPoints.http]
  address = ":80"
  # Redirect to HTTPS (why wouldn't you?)
  [entryPoints.http.http.redirections.entryPoint]
    to = "https"
    scheme = "https"

[entryPoints.https]
  address = ":443"
  [entryPoints.https.http.tls]
    certResolver = "main"

# Let's Encrypt
[certificatesResolvers.main.acme]
  email = "batman@example.com"
  storage = "acme.json"
  # uncomment to use staging CA for testing
  # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"
  [certificatesResolvers.main.acme.dnsChallenge]
    provider = "route53"
  # Uncomment to use HTTP validation, like a caveman!
  # [certificatesResolvers.main.acme.httpChallenge]
  #  entryPoint = "http"    

# Docker Traefik provider
[providers.docker]
  endpoint = "unix:///var/run/docker.sock"
  swarmMode = true
  watch = true
```

### Prepare the docker service config

!!! tip
    "We'll want an overlay network, independent of our traefik stack, so that we can attach/detach all our other stacks (including traefik) to the overlay network. This way, we can undeploy/redepoly the traefik stack without having to bring down every other stack first!" - voice of hard-won experience

Create `/var/data/config/traefikv2/traefikv2.yml` as follows:

```
version: "3.2"

# What is this?
#
# This stack exists solely to deploy the traefik_public overlay network, so that
# other stacks (including traefik-app) can attach to it

services:
  scratch:
    image: scratch
    deploy:
      replicas: 0
    networks:
      - public

networks:
  public:
    driver: overlay
    attachable: true
    ipam:
      config:
        - subnet: 172.16.200.0/24
```

--8<-- "premix-cta.md"

Create `/var/data/config/traefikv2/traefikv2.yml` as follows:

```
version: "3.2"

services:
  app:
    image: traefik:v2.4
    env_file: /var/data/config/traefikv2/traefikv2.env
    # Note below that we use host mode to avoid source nat being applied to our ingress HTTP/HTTPS sessions
    # Without host mode, all inbound sessions would have the source IP of the swarm nodes, rather than the
    # original source IP, which would impact logging. If you don't care about this, you can expose ports the 
    # "minimal" way instead
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
      - /var/data/config/traefikv2:/etc/traefik
      - /var/data/traefikv2/traefik.log:/traefik.log
      - /var/data/traefikv2/acme.json:/acme.json
    networks:
      - traefik_public
    # Global mode makes an instance of traefik listen on _every_ node, so that regardless of which
    # node the request arrives on, it'll be forwarded to the correct backend service.
    deploy:
      mode: global
      labels:
        - "traefik.docker.network=traefik_public"
        - "traefik.http.routers.api.rule=Host(`traefik.example.com`)"
        - "traefik.http.routers.api.entrypoints=https"
        - "traefik.http.routers.api.tls.domains[0].main=example.com"
        - "traefik.http.routers.api.tls.domains[0].sans=*.example.com"        
        - "traefik.http.routers.api.tls=true"
        - "traefik.http.routers.api.tls.certresolver=main"
        - "traefik.http.routers.api.service=api@internal"
        - "traefik.http.services.dummy.loadbalancer.server.port=9999"

        # uncomment this to enable forward authentication on the traefik api/dashboard
        #- "traefik.http.routers.api.middlewares=forward-auth"      
      placement:
        constraints: [node.role == manager]

networks:
  traefik_public:
    external: true
```

Docker won't start a service with a bind-mount to a non-existent file, so prepare an empty acme.json and traefik.log (_with the appropriate permissions_) by running:

```
touch /var/data/traefikv2/acme.json
touch /var/data/traefikv2/traefik.log
chmod 600 /var/data/traefikv2/acme.json
chmod 600 /var/data/traefikv2/traefik.log
```

!!! warning
    Pay attention above. You **must** set `acme.json`'s permissions to owner-readable-only, else the container will fail to start with an [ID-10T](https://en.wikipedia.org/wiki/User_error#ID-10-T_error) error!

Traefik will populate acme.json itself when it runs, but it needs to exist before the container will start (_Chicken, meet egg._)

Likewise with the log file.

## Serving

### Launch

First, launch the traefik stack, which will do nothing other than create an overlay network by running `docker stack deploy traefik -c /var/data/config/traefik/traefik.yml`

```
[root@kvm ~]# docker stack deploy traefik -c traefik.yml
Creating network traefik_public
Creating service traefik_scratch
[root@kvm ~]#
```

Now deploy the traefik application itself (*which will attach to the overlay network*) by running `docker stack deploy traefikv2 -c /var/data/config/traefikv2/traefikv2.yml`

```
[root@kvm ~]# docker stack deploy traefik-app -c traefikv2.yml
Creating service traefikv2_app
[root@kvm ~]#
```

Confirm traefik is running with `docker stack ps traefikv2`:

```
root@raphael:~# docker stack ps traefikv2
ID             NAME                                          IMAGE          NODE        DESIRED STATE   CURRENT STATE                ERROR     PORTS
lmvqcfhap08o   traefikv2_app.dz178s1aahv16bapzqcnzc03p       traefik:v2.4   donatello   Running         Running 2 minutes ago                  *:443->443/tcp,*:80->80/tcp
root@raphael:~#
```

### Check Traefik Dashboard

You should now be able to access[^1] your traefik instance on **https://traefik.<your domain\>** (*if your LetsEncrypt certificate is working*), or **http://<node IP\>:8080** (*if it's not*)- It'll look a little lonely currently (*below*), but we'll populate it as we add recipes :grin:

![Screenshot of Traefik, post-launch](/images/traefik-post-launch.png)

### Summary 

!!! summary
    We've achieved:

    * [X] An overlay network to permit traefik to access all future stacks we deploy
    * [X] Frontend proxy which will dynamically configure itself for new backend containers
    * [X] Automatic SSL support for all proxied resources

[^1]: Did you notice how no authentication was required to view the Traefik dashboard? Eek! We'll tackle that in the next section, regarding [Traefik Forward Authentication](/ha-docker-swarm/traefik-forward-auth/)!

--8<-- "recipe-footer.md"