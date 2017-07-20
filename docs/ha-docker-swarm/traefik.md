# Introduction

The platforms we plan to run on our cloud are generally web-based, and each listening on their own unique TCP port. When a container in a swarm exposes a port, then connecting to **any** swarm member on that port will result in your request being forwarded to the appropriate host running the container. (_Docker calls this the swarm "[routing mesh](https://docs.docker.com/engine/swarm/ingress/)"_)

So we get a rudimentary load balancer built into swarm. We could stop there, just exposing a series of ports on our hosts, and making them HA using keepalived.

There are some gaps to this approach though:

- No consideration is given to HTTPS. Implementation would have to be done manually, per-container.
- No mechanism is provided for authentication outside of that which the container providers. We may not **want** to expose every interface on every container to the world, especially if we are playing with tools or containers whose quality and origin are unknown.

To deal with these gaps, we need a front-end load-balancer, and in this design, that role is provided by [Traefik](https://traefik.io/).

## Prepare the host



````
mkdir ~/dockersock
cd ~/dockersock
curl -O https://raw.githubusercontent.com/dpw/selinux-dockersock/master/Makefile
curl -O https://raw.githubusercontent.com/dpw/selinux-dockersock/master/dockersock.te
make && semodule -i dockersock.pp
````
