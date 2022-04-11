# Networks

In order to avoid IP addressing conflicts as we bring swarm networks up/down, we will statically address each docker overlay network, and record the details below:

| Network                                                                                                               | Range          |
|-----------------------------------------------------------------------------------------------------------------------|----------------|
| [Traefik](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/traefik/)                                          | _unspecified_  |
| [Docker-cleanup](https://geek-cookbook.funkypenguin.co.nz/ha-docker-swarm/docker-swarm-mode/#setup-automated-cleanup) | 172.16.0.0/24  |
| [Mail Server](https://geek-cookbook.funkypenguin.co.nz/recipes/mail/)                                                 | 172.16.1.0/24  |
| [Gitlab](https://geek-cookbook.funkypenguin.co.nz/recipes/gitlab/)                                                    | 172.16.2.0/24  |
| [Wekan](https://geek-cookbook.funkypenguin.co.nz/recipes/wekan/)                                                      | 172.16.3.0/24  |
| [NightScout](https://geek-cookbook.funkypenguin.co.nz/recipes/nightscout/)                                            | 172.16.4.0/24  |
| [Tiny Tiny RSS](https://geek-cookbook.funkypenguin.co.nz/recipes/tiny-tiny-rss/)                                      | 172.16.5.0/24  |
| [Huginn](https://geek-cookbook.funkypenguin.co.nz/recipes/huginn/)                                                    | 172.16.6.0/24  |
| [Gollum](https://geek-cookbook.funkypenguin.co.nz/recipes/gollum/)                                                    | 
172.16.7.0/24  |
| [Polr](https://geek-cookbook.funkypenguin.co.nz/recipes/polr/)                                                        | 
172.16.9.0/24  |
| [Duplicity](https://geek-cookbook.funkypenguin.co.nz/recipes/duplicity/)                                              | 172.16.10.0/24 |
| [Autopirate](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/)                                            | 172.16.11.0/24 |
| [Nextcloud](https://geek-cookbook.funkypenguin.co.nz/recipes/nextcloud/)                                              | 172.16.12.0/24 |
| [Portainer](https://geek-cookbook.funkypenguin.co.nz/recipes/portainer/)                                              | 172.16.13.0/24 |
| [Home Assistant](https://geek-cookbook.funkypenguin.co.nz/recipes/homeassistant/)                                     | 172.16.14.0/24 |
| [OwnTracks](https://geek-cookbook.funkypenguin.co.nz/recipes/owntracks/)                                              | 172.16.15.0/24 |
| [Plex](https://geek-cookbook.funkypenguin.co.nz/recipes/plex/)                                                        | 172.16.16.0/24 |
| [Calibre-Web](https://geek-cookbook.funkypenguin.co.nz/recipes/calibre-web/)                                          | 172.16.18.0/24 |
| [Wallabag](https://geek-cookbook.funkypenguin.co.nz/recipes/wallabag/)                                                | 172.16.19.0/24 |
| [InstaPy](https://geek-cookbook.funkypenguin.co.nz/recipes/instapy/)                                                  | 172.16.20.0/24 |
| [Archivy](https://geek-cookbook.funkypenguin.co.nz/recipes/archivy/)                                                  | 172.16.21.0/24 |
| [MiniFlux](https://geek-cookbook.funkypenguin.co.nz/recipes/miniflux/)                                                | 172.16.22.0/24 |
| [Gitlab Runner](https://geek-cookbook.funkypenguin.co.nz/recipes/gitlab-runner/)                                      | 172.16.23.0/24 |
| [Bookstack](https://geek-cookbook.funkypenguin.co.nz/recipes/bookstack/)                                              | 172.16.33.0/24 |
| [Swarmprom](https://geek-cookbook.funkypenguin.co.nz/recipes/swarmprom/)                                              | 172.16.34.0/24 |
| [Realms](https://geek-cookbook.funkypenguin.co.nz/recipes/realms/)                                                    | 172.16.35.0/24 |
| [ElkarBackup](https://geek-cookbook.funkypenguin.co.nz/recipes/elkarbackup/)                                          | 172.16.36.0/24 |
| [OpenLDAP](https://geek-cookbook.funkypenguin.co.nz/recipes/openldap/)                                                | 172.16.39.0/24 |
| [PrivateBin](https://geek-cookbook.funkypenguin.co.nz/recipes/privatebin/)                                            | 172.16.41.0/24 |
| [Wetty](https://geek-cookbook.funkypenguin.co.nz/recipes/wetty/)                                                      | 172.16.45.0/24 |
| [phpIPAM](https://geek-cookbook.funkypenguin.co.nz/recipes/phpipam/)                                                  | 172.16.47.0/24 |
| [KeyCloak](https://geek-cookbook.funkypenguin.co.nz/recipes/keycloak/)                                                | 172.16.49.0/24 |
| [Duplicati](https://geek-cookbook.funkypenguin.co.nz/recipes/duplicati/)                                              | 172.16.55.0/24 |
| [Restic](https://geek-cookbook.funkypenguin.co.nz/recipes/restic/)                                                    | 172.16.56.0/24 |
| [Paperless NG](https://geek-cookbook.funkypenguin.co.nz/recipes/paperless/)                                           | 172.16.58.0/24 |
