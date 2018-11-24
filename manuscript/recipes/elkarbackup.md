hero: Not all heroes wear capes

!!! danger "This recipe is a work in progress"
    This recipe is **incomplete**, and is featured to align the [patrons](https://www.patreon.com/funkypenguin)'s "premix" repository with the cookbook.  "_premix_" is a private git repository available to [all Patreon patrons](https://www.patreon.com/funkypenguin), which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍

    So... There may be errors and inaccuracies. Jump into [Discord](http://chat.funkypenguin.co.nz) if you're encountering issues 😁


# Elkar Backup

ElkarBackup is a free open-source backup solution based on RSync/RSnapshot

![ElkarBackup Screenshot](../images/elkarbackup.png)

## Why is this a WIP?

!!! warning "Concerns re ongoing development"

    I have some concerns about the ongoing support of the project. The repo for the website was last committed **2 years ago**, and I've submitted a [PR](https://github.com/elkarbackup/elkarbackup.github.io/pull/2) for a blatant typo on the front page, which also shows up in the first google search result for "elkar backup".

    However, the code itself seems to be [updated frequently,](https://github.com/elkarbackup/elkarbackup/commits/master) the last update being 19 days ago.

What's missing from the recipe currently is:

1. An explanation for the environment variables, plus details re how to use scripts to send data offsite, like Duplicity does.
2. Details about ElkarBackup
3. A mysql container to backup the elkar database


## Details

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik_public) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/elkarbackup:

```
mkdir -p /var/data/elkarbackup/{backups,uploads,sshkeys}
```

### Prepare environment

Create elkarbackup.env, and populate with the following variables
```
SYMFONY__DATABASE__PASSWORD=password
EB_CRON=enabled
TZ='Spain/Madrid'

#SMTP
#SYMFONY__MAILER__HOST=
#SYMFONY__MAILER__USER=
#SYMFONY__MAILER__PASSWORD=
#SYMFONY__MAILER__FROM=

# For mysql
MYSQL_ROOT_PASSWORD=password

#oauth2_proxy
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: "3"

services:
  db:
    image: mariadb:10
    env_file: /var/data/config/elkarbackup/elkarbackup.env
    networks:
      - internal
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/data/runtime/elkarbackup3/db:/var/lib/mysql

  elkarbackup:
    image: elkarbackup/elkarbackup:1.3.0-apache
    env_file: /var/data/config/elkarbackup/elkarbackup.env
    networks:
      - internal
    volumes:
       - /etc/localtime:/etc/localtime:ro
       - /var/data/elkarbackup/backups:/app/backups
       - /var/data/elkarbackup/uploads:/app/uploads
       - /var/data/elkarbackup/sshkeys:/app/.ssh

   proxy:
     image: funkypenguin/oauth2_proxy
     env_file: /var/data/config/elkarbackup/elkarbackup.env
     networks:
       - traefik_public
       - internal
     deploy:
       labels:
         - traefik.frontend.rule=Host:elkarbackup.example.com
         - traefik.port=4180
     volumes:
       - /var/data/config/traefik/authenticated-emails.txt:/authenticated-emails.txt
     command: |
       -cookie-secure=false
       -upstream=http://app:80
       -redirect-url=https://elkarbackup.example.com
       -http-address=http://0.0.0.0:4180
       -email-domain=example.com
       -provider=github
       -authenticated-emails-file=/authenticated-emails.txt

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.36.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch ElkarBackup stack

Launch the ElkarBackup stack by running ```docker stack deploy elkarbackup -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

## Chef's Notes

1. If you wanted to expose the ElkarBackup UI directly, you could remove the oauth2_proxy from the design, and move the traefik_public-related labels directly to the app service. You'd also need to add the traefik_public network to the app service.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
