# Traefik

The platforms we plan to run on our cloud are generally web-based, and each listening on their own unique TCP port. When a container in a swarm exposes a port, then connecting to **any** swarm member on that port will result in your request being forwarded to the appropriate host running the container. (_Docker calls this the swarm "[routing mesh](https://docs.docker.com/engine/swarm/ingress/)"_)

So we get a rudimentary load balancer built into swarm. We could stop there, just exposing a series of ports on our hosts, and making them HA using keepalived.

There are some gaps to this approach though:

- No consideration is given to HTTPS. Implementation would have to be done manually, per-container.
- No mechanism is provided for authentication outside of that which the container providers. We may not **want** to expose every interface on every container to the world, especially if we are playing with tools or containers whose quality and origin are unknown.

To deal with these gaps, we need a front-end load-balancer, and in this design, that role is provided by [Traefik](https://traefik.io/).

![Traefik Screenshot](../images/traefik.png)

## Ingredients

!!! summary "You'll need"
    Already deployed:

    * [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph)

    New to this recipe:

    * [ ] Access to update your DNS records for manual/automated [LetsEncrypt](https://letsencrypt.org/docs/challenge-types/) DNS-01 validation, or ingress HTTP/HTTPS for HTTP-01 validation
  
## Preparation

### Prepare the host

The traefik container is aware of the __other__ docker containers in the swarm, because it has access to the docker socket at **/var/run/docker.sock**. This allows traefik to dynamically configure itself based on the labels found on containers in the swarm, which is hugely useful. To make this functionality work on a SELinux-enabled CentOS7 host, we need to add custom SELinux policy.

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

While it's possible to configure traefik via docker command arguments, I prefer to create a config file (`traefik.toml`). This allows me to change traefik's behaviour by simply changing the file, and keeps my docker config simple.

Create `/var/data/traefik/traefik.toml` as follows:

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

# Request wildcard certificates per https://docs.traefik.io/configuration/acme/#wildcard-domains
[[acme.domains]]
  main = "*.example.com"
  sans = ["example.com"]

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
domain = "example.com"
watch = true
swarmmode = true
```

### Prepare the docker service config

!!! tip
    "We'll want an overlay network, independent of our traefik stack, so that we can attach/detach all our other stacks (including traefik) to the overlay network. This way, we can undeploy/redepoly the traefik stack without having to bring every other stack first!" - voice of experience

Create `/var/data/config/traefik/traefik.yml` as follows:

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

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


Create `/var/data/config/traefik/traefik-app.yml` as follows:

```
version: "3"

services:
  traefik:
    image: traefik
    command: --web --docker --docker.swarmmode --docker.watch --docker.domain=example.com --logLevel=DEBUG
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
      - /var/data/config/traefik:/etc/traefik
      - /var/data/traefik/traefik.log:/traefik.log
      - /var/data/traefik/acme.json:/acme.json
    networks:
      - public
    # Global mode makes an instance of traefik listen on _every_ node, so that regardless of which
    # node the request arrives on, it'll be forwarded to the correct backend service.
    deploy:
      labels:
        - "traefik.enable=false"
      mode: global
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure     

networks:
  traefik_public:
    external: true
```

Docker won't start a service with a bind-mount to a non-existent file, so prepare an empty acme.json (_with the appropriate permissions_) by running:

```
touch /var/data/traefik/acme.json
chmod 600 /var/data/traefik/acme.json
```

!!! warning
    Pay attention above. You **must** set `acme.json`'s permissions to owner-readable-only, else the container will fail to start with an [ID-10T](https://en.wikipedia.org/wiki/User_error#ID-10-T_error) error!

Traefik will populate acme.json itself when it runs, but it needs to exist before the container will start (_Chicken, meet egg._)



## Serving

### Launch

First, launch the traefik stack, which will do nothing other than create an overlay network by running `docker stack deploy traefik -c /var/data/traefik/traefik.yml`

```
[root@kvm ~]# docker stack deploy traefik -c traefik.yml
Creating network traefik_public
Creating service traefik_scratch
[root@kvm ~]#
```

Now deploy the traefik appliation itself (*which will attach to the overlay network*) by running `docker stack deploy traefik-app -c /var/data/traefik/traefik-app.yml`

```
[root@kvm ~]# docker stack deploy traefik-app -c traefik-app.yml
Creating service traefik-app_app
[root@kvm ~]#
```

Confirm traefik is running with `docker stack ps traefik-app`:

```
[root@kvm ~]# docker stack ps traefik-app
ID                  NAME                                        IMAGE               NODE                     DESIRED STATE       CURRENT STATE            ERROR               PORTS
74uipz4sgasm        traefik-app_app.t4vcm8siwc9s1xj4c2o4orhtx   traefik:alpine      kvm.funkypenguin.co.nz   Running             Running 33 seconds ago                       *:443->443/tcp,*:80->80/tcp
[root@kvm ~]#
```

### Check Traefik Dashboard

You should now be able to access your traefik instance on http://<node IP\>:8080 - It'll look a little lonely currently (*below*), but we'll populate it as we add recipes :)

![Screenshot of Traefik, post-launch](/images/traefik-post-launch.png)

### Summary 

!!! summary
    We've achieved:

    * [X] An overlay network to permit traefik to access all future stacks we deploy
    * [X] Frontend proxy which will dynamically configure itself for new backend containers
    * [X] Automatic SSL support for all proxied resources


## Chef's Notes 

1. Did you notice how no authentication was required to view the Traefik dashboard? Eek! We'll tackle that in the next section, regarding [Traefik Forward Authentication](/ha-docker-swarm/traefik-forward-auth/)!

### Tip your waiter (support me) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
