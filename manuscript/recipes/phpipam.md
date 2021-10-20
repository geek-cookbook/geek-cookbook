---
description: Is that IP address in use?
---

# phpIPAM

phpIPAM is an open-source web IP address management application (_IPAM_). Its goal is to provide light, modern and useful IP address management. It is php-based application with MySQL database backend, using jQuery libraries, ajax and HTML5/CSS3 features.

![phpIPAM Screenshot](../images/phpipam.png)

phpIPAM fulfils a non-sexy, but important role - It helps you manage your IP address allocation.

## Why should you care about this?

You probably have a home network, with 20-30 IP addresses, for your family devices, your [IoT devices](/recipes/homeassistant), your smart TV, etc. If you want to (a) monitor them, and (b) audit who does what, you care about what IPs they're assigned by your DHCP server.

You could simple keep track of all devices with leases in your DHCP server, but what happens if your (_hypothetical?_) Ubiquity Edge Router X crashes and burns due to lack of disk space, and you loose track of all your leases? Well, you have to start from scratch, is what!

And that [HomeAssistant](/recipes/homeassistant/) config, which you so carefully compiled, refers to each device by IP/DNS name, so you'd better make sure you recreate it consistently!

Enter phpIPAM. A tool designed to help home keeps as well as large organisations keep track of their IP (_and VLAN, VRF, and AS number_) allocations.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in `/var/data/phpipam`:

```
mkdir /var/data/phpipam/databases-dump -p
mkdir /var/data/runtime/phpipam -p
```

### Prepare environment

Create `phpipam.env`, and populate with the following variables

```
# Setup for github, phpipam application
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=

# For MariaDB/MySQL database
MYSQL_ROOT_PASSWORD=imtoosecretformyshorts
MYSQL_DATABASE=phpipam
MYSQL_USER=phpipam
MYSQL_PASSWORD=secret

# phpIPAM-specific variables
MYSQL_ENV_MYSQL_USER=phpipam
MYSQL_ENV_MYSQL_PASSWORD=secret
MYSQL_ENV_MYSQL_DB=phpipam
MYSQL_ENV_MYSQL_HOST=db

# For backup
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```

Additionally, create `phpipam-backup.env`, and populate with the following variables:

```
# For MariaDB/MySQL database
MYSQL_ROOT_PASSWORD=imtoosecretformyshorts
MYSQL_DATABASE=phpipam
MYSQL_USER=phpipam
MYSQL_PASSWORD=secret

# For backup
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```



### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:

  db:
    image: mariadb:10
    env_file: /var/data/config/phpipam/phpipam.env
    networks:
      - internal
    volumes:
      - /var/data/runtime/phpipam/db:/var/lib/mysql

  app:
    image: pierrecdn/phpipam
    env_file: /var/data/config/phpipam/phpipam.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        # traefik common
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"

        # traefikv1
        - "traefik.frontend.rule=Host:phpipam.example.com"
        - "traefik.port=80"
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true           

        # traefikv2
        - "traefik.http.routers.phpipam.rule=Host(`phpipam.example.com`)"
        - "traefik.http.routers.phpipam.entrypoints=https"
        - "traefik.http.services.phpipam.loadbalancer.server.port=80" 
        - "traefik.http.routers.api.middlewares=forward-auth"           

  db-backup:
    image: mariadb:10
    env_file: /var/data/config/phpipam/phpipam.env
    volumes:
      - /var/data/phpipam/database-dump:/dump
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

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.47.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch phpIPAM stack

Launch the phpIPAM stack by running `docker stack deploy phpipam -c <path -to-docker-compose.yml>`

Log into your new instance at https://**YOUR-FQDN**, and follow the on-screen prompts to set your first user/password.

[^1]: If you wanted to expose the phpIPAM UI directly, you could remove the `traefik.http.routers.api.middlewares` label from the app container :thumbsup:

--8<-- "recipe-footer.md"