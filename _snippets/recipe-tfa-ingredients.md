## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your auth host (*"auth.yourdomain.com" is a good choice*), pointed to your [keepalived](/docker-swarm/keepalived/) IP