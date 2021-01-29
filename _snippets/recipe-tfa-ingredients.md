## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
    * [X] [Traefik](/ha-docker-swarm/traefik) configured per design

    New:

    * [ ] DNS entry for your auth host (*"auth.yourdomain.com" is a good choice*), pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP