hero: Backup all your stuff. Share it. Privately.

# NextCloud

[NextCloud](https://www.nextcloud.org/) (_a [fork of OwnCloud](https://owncloud.org/blog/owncloud-statement-concerning-the-formation-of-nextcloud-by-frank-karlitschek/), led by original developer Frank Karlitschek_) is a suite of client-server software for creating and using file hosting services. It is functionally similar to Dropbox, although Nextcloud is free and open-source, allowing anyone to install and operate it on a private server.
 - https://en.wikipedia.org/wiki/Nextcloud

![NextCloud Screenshot](../images/nextcloud.png)

This recipe is based on the official NextCloud docker image, but includes seprate containers ofor the database (_MariaDB_), Redis (_for transactional locking_), Apache Solr (_for full-text searching_), automated database backup, (_you *do* backup the stuff you care about, right?_) and a separate cron container for running NextCloud's 15-min crons.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories for [static data](/reference/data_layout/#static-data) to bind-mount into our container, so create them in /var/data/nextcloud (_so that they can be [backed up](/recipes/duplicity/)_)

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

--8<-- "premix-cta.md"

```yaml
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
    env_file: /var/data/config/nextcloud/nextcloud-db-backup.env
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

--8<-- "reference-networks.md"

## Serving

### Launch NextCloud stack

Launch the NextCloud stack by running ```docker stack deploy nextcloud -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "admin" and the password you specified in nextcloud.env.

### Enable redis

To make NextCloud [a little snappier](https://docs.nextcloud.com/server/13/admin_manual/configuration_server/caching_configuration.html), edit ```/var/data/nextcloud/config/config.php``` (_now that it's been created on the first container launch_), and add the following:

```
  'redis' => array(
     'host' => 'redis',
     'port' => 6379,
      ),
```

### Use service discovery

Want to use Calendar/Contacts on your iOS device? Want to avoid dictating long, rambling URL strings to your users, like ```https://nextcloud.batcave.com/remote.php/dav/principals/users/USERNAME/``` ?

Huzzah! NextCloud supports [service discovery for CalDAV/CardDAV](https://tools.ietf.org/html/rfc6764), allowing you to simply tell your device the primary URL of your server (_**nextcloud.batcave.org**, for example_), and have the device figure out the correct WebDAV path to use.

We (_and anyone else using the [NextCloud Docker image](https://hub.docker.com/_/nextcloud/)_) are using an SSL-terminating reverse proxy ([Traefik](/ha-docker-swarm/traefik/)) in front of our NextCloud container. In fact, it's not **possible** to setup SSL **within** the NextCloud container.

When using a reverse proxy, your device requests a URL from your proxy (https://nextcloud.batcave.com/.well-known/caldav), and the reverse proxy then passes that request **unencrypted** to the internal URL of the NextCloud instance (i.e., http://172.16.12.123/.well-known/caldav)

The Apache webserver on the NextCloud container (_knowing it was spoken to via HTTP_), responds with a 301 redirect to http://nextcloud.batcave.com/remote.php/dav/. See the problem? You requested an **HTTPS** (_encrypted_) url, and in return, you received a redirect to an **HTTP** (_unencrypted_) URL. Any sensible client (_iOS included_) will refuse such schenanigans.

To correct this, we need to tell NextCloud to always redirect the .well-known URLs to an HTTPS location. This can only be done **after** deploying NextCloud, since it's only on first launch of the container that the .htaccess file is created in the first place.

To make NextCloud service discovery work with Traefik reverse proxy, edit ```/var/data/nextcloud/html/.htaccess```, and change this:

```
RewriteRule ^\.well-known/carddav /remote.php/dav/ [R=301,L]
RewriteRule ^\.well-known/caldav /remote.php/dav/ [R=301,L]
```

To this:

```
RewriteRule ^\.well-known/carddav https://%{SERVER_NAME}/remote.php/dav/ [R=301,L]
RewriteRule ^\.well-known/caldav https://%{SERVER_NAME}/remote.php/dav/ [R=301,L]
```

Then restart your container with ```docker service update nextcloud_nextcloud --force``` to restart apache.

Your can test for success by running ```curl -i https://nextcloud.batcave.org/.well-known/carddav```. You should get a 301 redirect to your equivalent of https://nextcloud.batcave.org/remote.php/dav/, as below:

```
[davidy:~] % curl -i https://nextcloud.batcave.org/.well-known/carddav
HTTP/2 301
content-type: text/html; charset=iso-8859-1
date: Wed, 12 Dec 2018 08:30:11 GMT
location: https://nextcloud.batcave.org/remote.php/dav/
```

Note that this .htaccess can be overwritten by NextCloud, and you may have to reapply the change in future. I've created an [issue requesting a permanent fix](https://github.com/nextcloud/docker/issues/577).

[^1]: Since many of my other recipes use PostgreSQL, I'd have preferred to use Postgres over MariaDB, but MariaDB seems to be the [preferred database type](https://github.com/nextcloud/server/issues/5912).
[^2]: I'm [not the first user](https://github.com/nextcloud/docker/issues/528) to stumble across the service discovery bug with reverse proxies.

--8<-- "recipe-footer.md"