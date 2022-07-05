## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik) configured per design
    * [X] DNS entry for the hostname you intend to use (*or a wildcard*), pointed to your [keepalived](/docker-swarm/keepalived/) IP

    Related:

    * [X] [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/) to secure your Traefik-exposed services with an additional layer of authentication
