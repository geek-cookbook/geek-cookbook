# Networks

In order to avoid IP addressing conflicts as we bring swarm networks up/down, we will statically address each docker overlay network, and record the details below:

Network  | Range
--|--
[Traefik](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/traefik/)  | _unspecified_
[Docker-cleanup](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/docker-swarm-mode/#setup-automated-cleanup) | 172.16.0.0/24
[Mail Server](https://geek-cookbook.funkypenguin.co.nz/recipies/mail/)  | 172.16.1.0/24
[Gitlab](https://geek-cookbook.funkypenguin.co.nz/recipies/gitlab/) | 172.16.2.0/24
[Wekan](https://geek-cookbook.funkypenguin.co.nz/recipies/wekan/)  |  172.16.3.0/24
[Piwik](https://geek-cookbook.funkypenguin.co.nz/recipies/piwki/)  |  172.16.4.0/24
[Tiny Tiny RSS](https://geek-cookbook.funkypenguin.co.nz/recipies/tiny-tiny-rss/)  |  172.16.5.0/24
[Huginn](https://geek-cookbook.funkypenguin.co.nz/recipies/huginn/)  |  172.16.6.0/24
[Unifi](https://geek-cookbook.funkypenguin.co.nz/recipies/unifi/)  |  172.16.7.0/24
[Kanboard](https://geek-cookbook.funkypenguin.co.nz/recipies/kanboard/)  |  172.16.8.0/24
[Gollum](https://geek-cookbook.funkypenguin.co.nz/recipies/gollum/)  |  172.16.9.0/24
[Duplicity](https://geek-cookbook.funkypenguin.co.nz/recipies/duplicity/)  |  172.16.10.0/24
[Autopirate](https://geek-cookbook.funkypenguin.co.nz/recipies/autopirate/)  |  172.16.11.0/24
[Nextcloud](https://geek-cookbook.funkypenguin.co.nz/recipies/nextcloud/)  |  172.16.12.0/24
[Portainer](https://geek-cookbook.funkypenguin.co.nz/recipies/portainer/)  |  172.16.13.0/24
[Home-Assistant](https://geek-cookbook.funkypenguin.co.nz/recipies/home-assistant/)  |  172.16.14.0/24
[OwnTracks](https://geek-cookbook.funkypenguin.co.nz/recipies/owntracks/)  |  172.16.15.0/24
[Plex](https://geek-cookbook.funkypenguin.co.nz/recipies/plex/)  |  172.16.16.0/24
[Emby](https://geek-cookbook.funkypenguin.co.nz/recipies/emby/)  |  172.16.17.0/24
[Calibre-Web](https://geek-cookbook.funkypenguin.co.nz/recipies/calibre-web/)  |  172.16.18.0/24


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
