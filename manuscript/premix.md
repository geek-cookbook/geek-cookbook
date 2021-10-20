# Premix Repository

 "Premix" is a private git repository available to [GitHub sponsors](https://github.com/sponsors/funkypenguin), which includes:
 
 1. Necessary docker-compose and env files for all published recipes
 2. Ansible playbook for deploying the cookbook stack, as well as individual recipes
 3. Helm charts for deploying recipes into Kubernetes

The intention of Premix is that sponsors can launch any recipe with just a `git pull` followed by `ansible-playbook ...` (*Docker Swarm _or_ Kubernetes*), `docker stack deploy ...` (*Docker Swarm*), or `helm install ...` (*Kubernetes*).

## Data Layout

Generally, each recipe with necessary files is contained within its own folder. The intention is that a sponsor could run `git clone git@github.com:funkypenguin/geek-cookbook-premix.git /var/data/config`, and the recipes would be laid out per the [data layout](/reference/data_layout/).

Here's a sample of the directory structure:

??? "What will I find in the pre-mix?"
    ```
    .
    ├── README.md
    ├── ansible
    │   ├── README.md
    │   ├── ansible.cfg
    │   ├── carefully_destroy.yml
    │   ├── deploy.yml
    │   ├── deploy_swarm.yml
    │   ├── group_vars
    │   │   └── all
    │   │       ├── 01_fake_vault.yml
    │   │       ├── main.yml
    │   │       └── vault.yml
    │   ├── hosts.example
    │   └── roles
    │       ├── ceph
    │       │   ├── tasks
    │       │   │   ├── docker-swarm.yml
    │       │   │   ├── kubernetes.yml
    │       │   │   └── main.yml
    │       │   └── templates
    │       │       ├── cluster.yaml.j2
    │       │       ├── storageclass.yaml.j2
    │       │       └── toolbox.yaml.j2
    │       ├── destroy-proxmox
    │       │   ├── defaults
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   └── templates
    │       │       ├── main.tf.j2
    │       │       └── swarm_node.tf.j2
    │       ├── docker-stack
    │       │   ├── defaults
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   └── vars
    │       │       └── default.yaml
    │       ├── docker-swarm
    │       │   └── tasks
    │       │       └── main.yml
    │       ├── helm
    │       │   └── tasks
    │       │       └── main.yml
    │       ├── helm-chart
    │       │   ├── defaults
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   └── vars
    │       │       └── default.yaml
    │       ├── k3s-master
    │       │   ├── README.md
    │       │   ├── defaults
    │       │   │   └── main.yml
    │       │   ├── handlers
    │       │   │   └── main.yml
    │       │   ├── meta
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   ├── tests
    │       │   │   ├── inventory
    │       │   │   └── test.yml
    │       │   └── vars
    │       │       └── main.yml
    │       ├── k3s-worker
    │       │   ├── README.md
    │       │   ├── defaults
    │       │   │   └── main.yml
    │       │   ├── handlers
    │       │   │   └── main.yml
    │       │   ├── meta
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   ├── tests
    │       │   │   ├── inventory
    │       │   │   └── test.yml
    │       │   └── vars
    │       │       └── main.yml
    │       ├── keepalived
    │       │   └── tasks
    │       │       └── main.yml
    │       ├── proxmox
    │       │   ├── defaults
    │       │   │   └── main.yml
    │       │   ├── tasks
    │       │   │   └── main.yml
    │       │   └── templates
    │       │       ├── main.tf.j2
    │       │       └── swarm_node.tf.j2
    │       ├── traefik
    │       │   └── tasks
    │       │       └── main.yml
    │       ├── traefik-forward-auth
    │       │   └── tasks
    │       │       └── main.yml
    │       └── traefikv1
    │           └── tasks
    │               └── main.yml
    ├── autopirate
    │   ├── authenticated-emails.txt-sample
    │   ├── autopirate.yml
    │   ├── bazarr.env-sample
    │   ├── headphones.env-sample
    │   ├── heimdall.env-sample
    │   ├── lazylibrarian.env-sample
    │   ├── lidarr.env-sample
    │   ├── mylar.env-sample
    │   ├── nzbget.env-sample
    │   ├── nzbhydra.env-sample
    │   ├── ombi.env-sample
    │   ├── oscarr.env-sample
    │   ├── radarr.env-sample
    │   ├── sabnzbd.env-sample
    │   └── sonarr.env-sample
    ├── bitwarden
    │   ├── bitwarden.yml
    │   └── readme.md
    ├── bookstack
    │   ├── authenticated-emails-sample.txt
    │   ├── bookstack.env-sample
    │   └── bookstack.yml
    ├── calibre-web
    │   ├── authenticated-emails-sample.txt
    │   ├── calibre-web.env-sample
    │   └── calibre-web.yml
    ├── ceph
    ├── charts
    │   ├── autopirate
    │   │   ├── Chart.yaml
    │   │   ├── README.MD
    │   │   ├── charts
    │   │   │   └── funkycore-1.0.0.tgz
    │   │   ├── templates
    │   │   │   ├── NOTES.txt
    │   │   │   ├── _helpers.tpl
    │   │   │   ├── apps
    │   │   │   │   ├── bazarr
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── headphones
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── lazylibrarian
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── lidarr
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── mylar
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── nzbget
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── configmap.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── nzbhydra
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── ombi
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── radarr
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── rtorrent
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   ├── sabnzbd
    │   │   │   │   │   ├── config-pvc.yaml
    │   │   │   │   │   ├── configmap.yaml
    │   │   │   │   │   ├── deployment.yaml
    │   │   │   │   │   └── service.yaml
    │   │   │   │   └── sonarr
    │   │   │   │       ├── config-pvc.yaml
    │   │   │   │       ├── deployment.yaml
    │   │   │   │       └── service.yaml
    │   │   │   ├── download-pvc.yaml
    │   │   │   ├── ingress
    │   │   │   │   ├── kube.yaml
    │   │   │   │   └── traefik.yaml
    │   │   │   └── media-pvc.yaml
    │   │   └── values.yaml
    │   ├── autopirate-storage
    │   │   └── Chart.lock
    │   ├── funkycore
    │   │   ├── Chart.yaml
    │   │   ├── templates
    │   │   │   └── _helpers.tpl
    │   │   └── values.yaml
    │   ├── heimdall
    │   │   └── Chart.lock
    │   ├── huginn
    │   │   ├── Chart.yaml
    │   │   ├── README.MD
    │   │   ├── charts
    │   │   │   └── postgresql-8.3.0.tgz
    │   │   ├── myvalues.yaml
    │   │   ├── templates
    │   │   │   ├── _helpers.tpl
    │   │   │   ├── deployment.yaml
    │   │   │   ├── ingress
    │   │   │   │   ├── kube.yaml
    │   │   │   │   └── traefik.yaml
    │   │   │   ├── secret.yaml
    │   │   │   └── service.yaml
    │   │   └── values.yaml
    │   ├── lidarr
    │   │   └── Chart.lock
    │   ├── rtorrent
    │   │   └── Chart.lock
    │   └── wash-hands
    │       ├── Chart.yaml
    │       ├── charts
    │       │   ├── cert-manager-v0.13.0.tgz
    │       │   ├── goldilocks-2.1.0.tgz
    │       │   ├── grafana-1.2.5.tgz
    │       │   ├── kube-eagle-1.1.5.tgz
    │       │   ├── kured-1.4.2.tgz
    │       │   ├── loki-0.25.0.tgz
    │       │   ├── nginx-ingress-1.30.1.tgz
    │       │   ├── prometheus-operator-0.11.1.tgz
    │       │   └── promtail-0.18.0.tgz
    │       ├── manifests
    │       │   └── wash-hands
    │       │       ├── charts
    │       │       │   ├── cert-manager
    │       │       │   │   └── templates
    │       │       │   │       ├── cainjector-deployment.yaml
    │       │       │   │       ├── cainjector-rbac.yaml
    │       │       │   │       ├── cainjector-serviceaccount.yaml
    │       │       │   │       ├── deployment.yaml
    │       │       │   │       ├── rbac.yaml
    │       │       │   │       ├── service.yaml
    │       │       │   │       ├── serviceaccount.yaml
    │       │       │   │       ├── webhook-deployment.yaml
    │       │       │   │       ├── webhook-mutating-webhook.yaml
    │       │       │   │       ├── webhook-rbac.yaml
    │       │       │   │       ├── webhook-service.yaml
    │       │       │   │       ├── webhook-serviceaccount.yaml
    │       │       │   │       └── webhook-validating-webhook.yaml
    │       │       │   ├── goldilocks
    │       │       │   │   └── templates
    │       │       │   │       ├── controller-clusterrole.yaml
    │       │       │   │       ├── controller-clusterrolebinding.yaml
    │       │       │   │       ├── controller-deployment.yaml
    │       │       │   │       ├── controller-serviceaccount.yaml
    │       │       │   │       ├── dashboard-clusterrole.yaml
    │       │       │   │       ├── dashboard-clusterrolebinding.yaml
    │       │       │   │       ├── dashboard-deployment.yaml
    │       │       │   │       ├── dashboard-service.yaml
    │       │       │   │       └── dashboard-serviceaccount.yaml
    │       │       │   ├── kured
    │       │       │   │   └── templates
    │       │       │   │       ├── clusterrole.yaml
    │       │       │   │       ├── clusterrolebinding.yaml
    │       │       │   │       ├── daemonset.yaml
    │       │       │   │       ├── role.yaml
    │       │       │   │       ├── rolebinding.yaml
    │       │       │   │       └── serviceaccount.yaml
    │       │       │   └── nginx-ingress
    │       │       │       └── templates
    │       │       │           ├── clusterrole.yaml
    │       │       │           ├── clusterrolebinding.yaml
    │       │       │           ├── controller-deployment.yaml
    │       │       │           ├── controller-role.yaml
    │       │       │           ├── controller-rolebinding.yaml
    │       │       │           ├── controller-service.yaml
    │       │       │           ├── controller-serviceaccount.yaml
    │       │       │           ├── default-backend-deployment.yaml
    │       │       │           ├── default-backend-service.yaml
    │       │       │           └── default-backend-serviceaccount.yaml
    │       │       └── templates
    │       │           ├── issuer-letsencrypt-staging-cloudflare.yaml
    │       │           ├── issuer-letsencrypt-staging.yaml
    │       │           ├── secret.yaml
    │       │           └── test.yaml
    │       ├── myvalues.yaml
    │       ├── templates
    │       │   ├── issuer-letsencrypt-prod.yaml
    │       │   ├── issuer-letsencrypt-staging.yaml
    │       │   └── secret.yaml
    │       └── values.yaml
    ├── cryptominer
    │   ├── monitor-gpu.sh
    │   └── stats-to-influxdb.sh
    ├── dex
    │   ├── README.md
    │   ├── config.yml.example
    │   └── dex.yml
    ├── diskover
    │   ├── diskover.env-sample
    │   ├── diskover.yml
    │   └── diskoverdash.env-sample
    ├── docker-cleanup
    │   ├── docker-cleanup.env-sample
    │   └── docker-cleanup.yml
    ├── dozzle
    │   ├── authenticated-emails.txt-sample
    │   ├── dozzle.env-sample
    │   └── dozzle.yml
    ├── duplicacy
    │   ├── authenticated-emails.txt-sample
    │   ├── duplicacy.env
    │   └── duplicacy.yml
    ├── duplicity
    │   ├── duplicity.env-sample
    │   └── duplicity.yml
    ├── elkarbackup
    │   ├── elkarbackup.env-sample
    │   ├── elkarbackup.yml
    │   └── elkarbackup.yml.proxy
    ├── emby
    │   ├── emby.env-sample
    │   └── emby.yml
    ├── filebrowser
    │   ├── README.md
    │   ├── config.json
    │   ├── filebrowser.env.sample
    │   ├── filebrowser.yml
    │   ├── hostname
    │   ├── hosts
    │   └── resolv.conf
    ├── ghost
    │   └── ghost.yml
    ├── gitlab
    │   └── gitlab.yml
    ├── gollum
    │   ├── authenticated-emails-sample.txt
    │   ├── gollum.env-sample
    │   └── gollum.yml
    ├── hackmd
    │   ├── authenticated-emails-sample.txt
    │   ├── hackmd-backup.env
    │   ├── hackmd.env
    │   └── hackmd.yml
    ├── homeassistant
    │   ├── README.md
    │   ├── grafana.env-sample
    │   ├── homeassistant.env-sample
    │   └── homeassistant.yml
    ├── huginn
    │   ├── huginn.env-sample
    │   ├── huginn.yml
    │   └── kubernetes
    │       ├── app.yml
    │       ├── db-persistent-volumeclaim.yml
    │       ├── db.yml
    │       ├── ingress.yml
    │       └── namespace.yml
    ├── instapy
    │   └── instapy.yml
    ├── jellyfin
    │   ├── jellyfin.env-sample
    │   ├── jellyfin.yml
    │   └── readme.md
    ├── kanboard
    │   ├── authenticated-emails-sample.txt
    │   ├── kanboard.env-sample
    │   ├── kanboard.yml
    │   └── kubernetes
    │       ├── app-persistent-volumeclaim.yml
    │       ├── app.yml
    │       ├── config.php
    │       ├── ingress.yml
    │       └── namespace.yml
    ├── keycloak
    │   ├── keycloak-backup.env-sample
    │   ├── keycloak.env-sample
    │   └── keycloak.yml
    ├── mailserver
    │   ├── mailserver.env-sample
    │   └── mailserver.yml
    ├── mastodon
    │   └── mastodon.yml
    ├── mattermost
    │   ├── mattermost-backup.env-sample
    │   ├── mattermost.env-sample
    │   └── mattermost.yml
    ├── mayan
    │   ├── authenticated-emails-sample.txt
    │   ├── mayan-backup.env
    │   ├── mayan.env
    │   └── mayan.yml
    ├── miniflux
    │   ├── kubernetes
    │   │   ├── app.yml
    │   │   ├── db-persistent-volumeclaim.yml
    │   │   ├── db.yml
    │   │   ├── ingress.yml
    │   │   └── namespace.yml
    │   ├── miniflux-backup.env-sample
    │   ├── miniflux.env-sample
    │   └── miniflux.yml
    ├── minio
    │   ├── minio.env-sample
    │   └── minio.yml
    ├── munin
    │   ├── munin.env-sample
    │   └── munin.yml
    ├── nextcloud
    │   ├── kubernetes
    │   │   ├── app-persistent-volumeclaim.yml
    │   │   ├── app.yml
    │   │   ├── db-persistent-volumeclaim.yml
    │   │   ├── db.yml
    │   │   ├── ingress.yml
    │   │   └── namespace.yml
    │   ├── nextcloud.env-sample
    │   └── nextcloud.yml
    ├── owntracks
    │   ├── owntracks.env
    │   └── owntracks.yml
    ├── phpipam
    │   ├── nginx.conf-sample
    │   ├── phpipam-backup.env-sample
    │   ├── phpipam.env-sample
    │   └── phpipam.yml
    ├── piwik
    │   └── piwik.yml
    ├── plex
    │   ├── nowshowing.env-sample
    │   ├── plex.env-sample
    │   ├── plex.yml
    │   └── tautulli.env-sample
    ├── portainer
    │   ├── portainer-agent-stack.yml
    │   ├── portainer.env-sample
    │   ├── portainer.yml
    │   └── portainer_with_oauth.yml
    ├── privatebin
    │   ├── authenticated-emails.txt-sample
    │   ├── privatebin.env-sample
    │   └── privatebin.yml
    ├── realms
    │   ├── authenticated-emails-sample.txt
    │   ├── bookstack_authenticated-emails-sample.txt
    │   ├── realms.env
    │   └── realms.yml
    ├── registry
    │   ├── registry-mirror-config.yml
    │   └── registry.yml
    ├── shaarli
    │   ├── authenticated-emails-sample.txt
    │   ├── shaarli.env
    │   ├── shaarli.env-sample
    │   └── shaarli.yml
    ├── shepherd
    │   ├── shepherd.env-sample
    │   └── shepherd.yml
    ├── swarmprom
    │   ├── Caddyfile
    │   ├── alertmanager.env-sample
    │   ├── grafana.env-sample
    │   ├── prometheus.env-sample
    │   ├── swarm_node.rules.yml
    │   ├── swarm_task.rules.yml
    │   ├── swarmprom.yml
    │   └── unsee.env-sample
    ├── tools
    │   ├── README.MD.TEMPLATE
    │   ├── aliases.sh
    │   ├── chart.sh
    │   ├── helm-boilerplate
    │   │   ├── Chart.yaml
    │   │   ├── templates
    │   │   │   ├── NOTES.TXT
    │   │   │   ├── _helpers.tpl
    │   │   │   ├── deployment.yaml
    │   │   │   ├── ingress
    │   │   │   │   ├── kube.yaml
    │   │   │   │   └── traefik.yaml
    │   │   │   ├── secret.yaml
    │   │   │   └── service.yaml
    │   │   └── values.yaml
    │   └── mkreadme.py
    ├── traefik
    │   ├── traefik.env-sample
    │   └── traefik.yml
    ├── traefik-forward-auth
    │   ├── README-traefik-with-non-swarm-backends.txt
    │   ├── traefik-forward-auth.env-sample
    │   └── traefik-forward-auth.yml
    ├── traefikv1
    │   ├── README-traefik-with-non-swarm-backends.txt
    │   ├── authenticated-emails.txt-sample
    │   ├── traefik.toml-sample
    │   ├── traefikv1.env-sample
    │   └── traefikv1.yml
    ├── ttrss
    │   ├── ttrss.env-sample
    │   └── ttrss.yml
    ├── turtle-pool
    │   └── kubernetes
    │       ├── README.md
    │       ├── config.js
    │       ├── custom.css
    │       ├── daemon-persistent-volumeclaim.yml
    │       ├── daemon.yml
    │       ├── namespace.yml
    │       ├── pool-ingress.yml
    │       ├── pool-persistent-volumeclaim.yml
    │       ├── pool-service-nodeport.yml
    │       ├── pool-service.yml
    │       ├── pool.yml
    │       ├── redis-persistent-volumeclaim.yml
    │       ├── redis.conf
    │       ├── redis.yml
    │       ├── trtl.json-example
    │       ├── wallet-persistent-volumeclaim.yml
    │       ├── wallet.conf-example
    │       ├── wallet.yml
    │       └── webhook_token.secret-example
    ├── unifi
    │   ├── authenticated-emails-sample.txt
    │   ├── kubernetes
    │   │   ├── authenticated-emails-sample.txt
    │   │   ├── controller-persistent-volumeclaim.yml
    │   │   ├── ingress.yml
    │   │   ├── namespace.yml
    │   │   ├── proxy.yaml
    │   │   ├── service-controller-external.yml
    │   │   └── unifi.yaml
    │   ├── unifi.yml
    │   └── unifi_with_proxy.yml
    ├── wallabag
    │   ├── authenticated-emails.txt-sample
    │   ├── wallabag-backup.env-sample
    │   ├── wallabag.env-sample
    │   └── wallabag.yml
    ├── wash-hands
    │   ├── README.md
    │   ├── azure-pipelines.yml
    │   ├── manifests
    │   │   └── wash-hands
    │   │       └── charts
    │   │           ├── goldilocks
    │   │           │   └── templates
    │   │           │       ├── controller-clusterrole.yaml
    │   │           │       ├── controller-clusterrolebinding.yaml
    │   │           │       ├── controller-deployment.yaml
    │   │           │       ├── controller-serviceaccount.yaml
    │   │           │       ├── dashboard-clusterrole.yaml
    │   │           │       ├── dashboard-clusterrolebinding.yaml
    │   │           │       ├── dashboard-deployment.yaml
    │   │           │       ├── dashboard-service.yaml
    │   │           │       └── dashboard-serviceaccount.yaml
    │   │           ├── kured
    │   │           │   └── templates
    │   │           │       ├── clusterrole.yaml
    │   │           │       ├── clusterrolebinding.yaml
    │   │           │       ├── daemonset.yaml
    │   │           │       ├── role.yaml
    │   │           │       ├── rolebinding.yaml
    │   │           │       └── serviceaccount.yaml
    │   │           └── nginx-ingress
    │   │               └── templates
    │   │                   ├── clusterrole.yaml
    │   │                   ├── clusterrolebinding.yaml
    │   │                   ├── controller-deployment.yaml
    │   │                   ├── controller-role.yaml
    │   │                   ├── controller-rolebinding.yaml
    │   │                   ├── controller-service.yaml
    │   │                   ├── controller-serviceaccount.yaml
    │   │                   ├── default-backend-deployment.yaml
    │   │                   ├── default-backend-service.yaml
    │   │                   └── default-backend-serviceaccount.yaml
    │   └── scripts
    │       └── local-ci.sh
    ├── wekan
    │   ├── authenticated-emails-sample.txt
    │   ├── wekan.env-sample
    │   └── wekan.yml
    └── wetty
        ├── wetty.env-sample
        └── wetty.yml

    166 directories, 422 files
    ```
