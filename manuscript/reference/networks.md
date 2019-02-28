# Networks

In order to avoid IP addressing conflicts as we bring swarm networks up/down, we will statically address each docker overlay network, and record the details below:

Network  | Range
--|--
[Traefik](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/traefik/)  | _unspecified_
[Docker-cleanup](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/docker-swarm-mode/#setup-automated-cleanup) | 172.16.0.0/24
[Mail Server](https://geek-cookbook.funkypenguin.co.nz/recipes/mail/)  | 172.16.1.0/24
[Gitlab](https://geek-cookbook.funkypenguin.co.nz/recipes/gitlab/) | 172.16.2.0/24
[Wekan](https://geek-cookbook.funkypenguin.co.nz/recipes/wekan/)  |  172.16.3.0/24
[Piwik](https://geek-cookbook.funkypenguin.co.nz/recipes/piwki/)  |  172.16.4.0/24
[Tiny Tiny RSS](https://geek-cookbook.funkypenguin.co.nz/recipes/tiny-tiny-rss/)  |  172.16.5.0/24
[Huginn](https://geek-cookbook.funkypenguin.co.nz/recipes/huginn/)  |  172.16.6.0/24
[Unifi](https://geek-cookbook.funkypenguin.co.nz/recipes/unifi/)  |  172.16.7.0/24
[Kanboard](https://geek-cookbook.funkypenguin.co.nz/recipes/kanboard/)  |  172.16.8.0/24
[Gollum](https://geek-cookbook.funkypenguin.co.nz/recipes/gollum/)  |  172.16.9.0/24
[Duplicity](https://geek-cookbook.funkypenguin.co.nz/recipes/duplicity/)  |  172.16.10.0/24
[Autopirate](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/)  |  172.16.11.0/24
[Nextcloud](https://geek-cookbook.funkypenguin.co.nz/recipes/nextcloud/)  |  172.16.12.0/24
[Portainer](https://geek-cookbook.funkypenguin.co.nz/recipes/portainer/)  |  172.16.13.0/24
[Home-Assistant](https://geek-cookbook.funkypenguin.co.nz/recipes/home-assistant/)  |  172.16.14.0/24
[OwnTracks](https://geek-cookbook.funkypenguin.co.nz/recipes/owntracks/)  |  172.16.15.0/24
[Plex](https://geek-cookbook.funkypenguin.co.nz/recipes/plex/)  |  172.16.16.0/24
[Emby](https://geek-cookbook.funkypenguin.co.nz/recipes/emby/)  |  172.16.17.0/24
[Calibre-Web](https://geek-cookbook.funkypenguin.co.nz/recipes/calibre-web/)  |  172.16.18.0/24
[Wallabag](https://geek-cookbook.funkypenguin.co.nz/recipes/wallabag/)  |  172.16.19.0/24
[InstaPy](https://geek-cookbook.funkypenguin.co.nz/recipes/instapy/)  |  172.16.20.0/24
[Turtle Pool](https://geek-cookbook.funkypenguin.co.nz/recipes/turtle-pool/)  |  172.16.21.0/24
[MiniFlux](https://geek-cookbook.funkypenguin.co.nz/recipes/miniflux/)  |  172.16.22.0/24
[Gitlab Runner](https://geek-cookbook.funkypenguin.co.nz/recipes/gitlab-runner/)  |  172.16.23.0/24
[Munin](https://geek-cookbook.funkypenguin.co.nz/recipes/munin/)  |  172.16.24.0/24
[Masari Mining Pool](https://geek-cookbook.funkypenguin.co.nz/recipes/cryptonote-mining-pool/masari/)  |  172.16.25.0/24
[Athena Mining Pool](https://geek-cookbook.funkypenguin.co.nz/recipes/cryptonote-mining-pool/athena/)  |  172.16.26.0/24
[Bookstack](https://geek-cookbook.funkypenguin.co.nz/recipes/bookstack/)  |  172.16.33.0/24
[Swarmprom](https://geek-cookbook.funkypenguin.co.nz/recipes/swarmprom/)  |  172.16.34.0/24
[Realms](https://geek-cookbook.funkypenguin.co.nz/recipes/realms/)  |  172.16.35.0/24
[ElkarBackup](https://geek-cookbook.funkypenguin.co.nz/recipes/elkarbackp/)  |  172.16.36.0/24
[Mayan EDMS](https://geek-cookbook.funkypenguin.co.nz/recipes/realms/)  |  172.16.37.0/24
[Shaarli](https://geek-cookbook.funkypenguin.co.nz/recipes/shaarli/)  |  172.16.38.0/24
[OpenLDAP](https://geek-cookbook.funkypenguin.co.nz/recipes/openldap/)  |  172.16.39.0/24
[MatterMost](https://geek-cookbook.funkypenguin.co.nz/recipes/mattermost/)  |  172.16.40.0/24
[PrivateBin](https://geek-cookbook.funkypenguin.co.nz/recipes/privatebin/)  |  172.16.41.0/24
[Mayan EDMS](https://geek-cookbook.funkypenguin.co.nz/recipes/mayan-edms/)  |  172.16.42.0/24
[Hack MD](https://geek-cookbook.funkypenguin.co.nz/recipes/hackmd/)  |  172.16.43.0/24
[FlightAirMap](https://geek-cookbook.funkypenguin.co.nz/recipes/flightairmap/)  |172.16.44.0/24
[Wetty](https://geek-cookbook.funkypenguin.co.nz/recipes/wetty/)  |  172.16.45.0/24
[FileBrowser](https://geek-cookbook.funkypenguin.co.nz/recipes/filebrowser/)  |  172.16.46.0/24
[phpIPAM](https://geek-cookbook.funkypenguin.co.nz/recipes/phpipam/)  |  172.16.47.0/24
[Dozzle](https://geek-cookbook.funkypenguin.co.nz/recipes/dozzle/)  |  172.16.48.0/24


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
