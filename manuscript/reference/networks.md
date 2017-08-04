# Networks

In order to avoid IP addressing conflicts as we bring swarm networks up/down, we will statically address each docker overlay network, and record the details below:

Network  | Range
--|--
[Traefik](/ha-docker-swarm/traefik/)  | _unspecified_
[Mail Server](/recipies/mail/)  | 172.16.1.0/24
[Gitlab](/recipies/gitlab/) | 172.16.2.0/24
[Wekan](/recipies/wekan/)  |  172.16.3.0/24
