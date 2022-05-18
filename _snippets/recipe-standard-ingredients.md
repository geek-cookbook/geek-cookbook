## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
    * [X] [Traefik](/ha-docker-swarm/traefik) configured per design
    * [X] DNS entry for the hostname you intend to use (*or a wildcard*), pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP

    Related:

    * [X] [Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/) to secure your Traefik-exposed services with an additional layer of authentication
