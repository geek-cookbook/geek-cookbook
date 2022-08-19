---
title: Docker Swarm Network allocations
---
# Networks

In order to avoid IP addressing conflicts as we bring swarm networks up/down, we will statically address each docker overlay network, and record the details below:

| Network                                                                                                               | Range          |
|-----------------------------------------------------------------------------------------------------------------------|----------------|
| [Traefik](/docker-swarm/traefik/)                                          | _unspecified_  |
| [Docker-cleanup](/docker-swarm/docker-swarm-mode/#setup-automated-cleanup)    | 172.16.0.0/24  |
| [Mail Server](/recipes/mail/)                                                 | 172.16.1.0/24  |
| [Gitlab](/recipes/gitlab/)                                                    | 172.16.2.0/24  |
| [Wekan](/recipes/wekan/)                                                      | 172.16.3.0/24  |
| [NightScout](/recipes/nightscout/)                                            | 172.16.4.0/24  |
| [Tiny Tiny RSS](/recipes/tiny-tiny-rss/)                                      | 172.16.5.0/24  |
| [Huginn](/recipes/huginn/)                                                    | 172.16.6.0/24  |
| [Gollum](/recipes/gollum/)                                                    | 172.16.7.0/24  |
| Immich (coming soon!)                                                         | 172.16.8.0/24  |
| Mastodon (coming soon!)                                                       | 172.16.9.0/24  |
| [Duplicity](/recipes/duplicity/)                                              | 172.16.10.0/24 |
| [Autopirate](/recipes/autopirate/)                                            | 172.16.11.0/24 |
| [Nextcloud](/recipes/nextcloud/)                                              | 172.16.12.0/24 |
| [Portainer](/recipes/portainer/)                                              | 172.16.13.0/24 |
| [Home Assistant](/recipes/homeassistant/)                                     | 172.16.14.0/24 |
| [OwnTracks](/recipes/owntracks/)                                              | 172.16.15.0/24 |
| [Plex](/recipes/plex/)                                                        | 172.16.16.0/24 |
| [Calibre-Web](/recipes/calibre-web/)                                          | 172.16.18.0/24 |
| [Wallabag](/recipes/wallabag/)                                                | 172.16.19.0/24 |
| [InstaPy](/recipes/instapy/)                                                  | 172.16.20.0/24 |
| [MiniFlux](/recipes/miniflux/)                                                | 172.16.22.0/24 |
| [Gitlab Runner](/recipes/gitlab-runner/)                                      | 172.16.23.0/24 |
| [Bookstack](/recipes/bookstack/)                                              | 172.16.33.0/24 |
| [Swarmprom](/recipes/swarmprom/)                                              | 172.16.34.0/24 |
| [Realms](/recipes/realms/)                                                    | 172.16.35.0/24 |
| [ElkarBackup](/recipes/elkarbackup/)                                          | 172.16.36.0/24 |
| [OpenLDAP](/recipes/openldap/)                                                | 172.16.39.0/24 |
| [PrivateBin](/recipes/privatebin/)                                            | 172.16.41.0/24 |
| [Wetty](/recipes/wetty/)                                                      | 172.16.45.0/24 |
| [phpIPAM](/recipes/phpipam/)                                                  | 172.16.47.0/24 |
| [Keycloak](/recipes/keycloak/)                                                | 172.16.49.0/24 |
| [Duplicati](/recipes/duplicati/)                                              | 172.16.55.0/24 |
| [Restic](/recipes/restic/)                                                    | 172.16.56.0/24 |
| [Paperless NG](/recipes/paperless-ng/)                                        | 172.16.58.0/24 |
