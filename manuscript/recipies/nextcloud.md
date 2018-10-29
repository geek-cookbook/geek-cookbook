hero: Backup all your stuff. Share it. Privately.

# NextCloud

[NextCloud](https://www.nextcloud.org/) (_a [fork of OwnCloud](https://owncloud.org/blog/owncloud-statement-concerning-the-formation-of-nextcloud-by-frank-karlitschek/), led by original developer Frank Karlitschek_) is a suite of client-server software for creating and using file hosting services. It is functionally similar to Dropbox, although Nextcloud is free and open-source, allowing anyone to install and operate it on a private server.
 - https://en.wikipedia.org/wiki/Nextcloud

![NextCloud Screenshot](../images/nextcloud.png)

This recipe is based on the official NextCloud docker image, but includes seprate containers ofor the database (_MariaDB_), Redis (_for transactional locking_), Apache Solr (_for full-text searching_), automated database backup, (_you *do* backup the stuff you care about, right?_) and a separate cron container for running NextCloud's 15-min crons.

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. DNS entry pointing your NextCloud url (_nextcloud.example.com_) to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need several directories for [static data](/reference/data_layout/#static-data) to bind-mount into our container, so create them in /var/data/nextcloud (_so that they can be [backed up](/recipies/duplicity/)_)

```
mkdir /var/data/nextcloud
cd /var/data/nextcloud
mkdir -p {html,apps,config,data,database-dump}
```

Now make **more** directories for [runtime data](/reference/data_layout/#runtime-data) (_so that they can be **not** backed-up_):

```
mkdir /var/data/runtime/nextcloud
cd /var/data/runtime/nextcloud
mkdir -p {db,redis}
```


### Prepare environment

Create nextcloud.env, and populate with the following variables
```
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=FVuojphozxMVyaYCUWomiP9b
MYSQL_HOST=db

# For mysql
MYSQL_ROOT_PASSWORD=<set to something secure>
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=set to something secure>
```

Now create a **separate** nextcloud-db-backup.env file, to capture the environment variables necessary to perform the backup. (_If the same variables are shared with the mariadb container, they [cause issues](https://discourse.geek-kitchen.funkypenguin.co.nz/t/nextcloud-funky-penguins-geek-cookbook/254/3?u=funkypenguin) with database access_)

````
# For database backup (keep 7 days daily backups)
MYSQL_PWD=<set to something secure, same as MYSQL_ROOT_PASSWORD above>
MYSQL_USER=root
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
````

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: "3.0"

services:
  nextcloud:
    image: nextcloud
    env_file: /var/data/config/nextcloud/nextcloud.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:nextcloud.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=80
    volumes:
    - /var/data/nextcloud/html:/var/www/html
    - /var/data/nextcloud/apps:/var/www/html/custom_apps
    - /var/data/nextcloud/config:/var/www/html/config
    - /var/data/nextcloud/data:/var/www/html/data

  db:
    image: mariadb:10
    env_file: /var/data/config/nextcloud/nextcloud.env
    networks:
      - internal
    volumes:
      - /var/data/runtime/nextcloud/db:/var/lib/mysql

  db-backup:
    image: mariadb:10
    env_file: /var/data/config/nextcloud/nextcloud.env
    volumes:
      - /var/data/nextcloud/database-dump:/dump
      - /etc/localtime:/etc/localtime:ro
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        mysqldump -h db --all-databases | gzip -c > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.sql.gz
        (ls -t /dump/dump*.sql.gz|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.sql.gz)|sort|uniq -u|xargs rm -- {}
        sleep $$BACKUP_FREQUENCY
      done
      EOF'
    networks:
    - internal

  redis:
    image: redis:alpine
    networks:
      - internal
    volumes:
      - /var/data/runtime/nextcloud/redis:/data

  cron:
    image: nextcloud
    volumes:
      - /var/data/nextcloud/:/var/www/html
    user: www-data
    networks:
      - internal
    entrypoint: |
      bash -c 'bash -s <<EOF
        trap "break;exit" SIGHUP SIGINT SIGTERM
        while [ ! -f /var/www/html/config/config.php ]; do
          sleep 1
        done
        while true; do
          php -f /var/www/html/cron.php
          sleep 15m
        done
      EOF'

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.12.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch NextCloud stack

Launch the NextCloud stack by running ```docker stack deploy nextcloud -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "admin" and the password you specified in nextcloud.env.

### Adding full-text search support (optional)

Once logged in as an admin user, navigate to https://<your FQDN>/index.php/settings/apps, and install the "**nextant**" app for full-text search

Then navigate to https://<your FQDN>/index.php/settings/admin/additional, scroll down to **Nextant (Full Text Search)**, and enter the following:

* Address of your solr servlet : **http://solr:8983/solr/**
* Core: **nextant**

## Chef's Notes

1. Since many of my other recipies use PostgreSQL, I'd have preferred to use Postgres over MariaDB, but MariaDB seems to be the [preferred database type](https://github.com/nextcloud/server/issues/5912).

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
