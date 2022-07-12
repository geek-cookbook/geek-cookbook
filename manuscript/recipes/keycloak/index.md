---
title: Run Keycloak behind traefik in Docker
---

# Keycloak (in Docker Swarm)

[Keycloak](https://www.keycloak.org/) is "_an open source identity and access management solution_". Using a local database, or a variety of backends (_think [OpenLDAP](/recipes/openldap/)_), you can provide Single Sign-On (SSO) using OpenID, OAuth 2.0, and SAML.

Keycloak's OpenID provider can also be used in combination with [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/), to protect [vulnerable services](/recipes/autopirate/nzbget/) with an extra layer of authentication.

![Keycloak Screenshot](../../images/keycloak.png){ loading=lazy }

--8<-- "recipe-standard-ingredients.md"

## Setup

### Filesystem paths

We'll need several directories to bind-mount into our container for both runtime and backup data, so create them as per the following example:

```bash
mkdir -p /var/data/runtime/keycloak/database
mkdir -p /var/data/keycloak/database-dump
```

### Environment vars

Create `/var/data/config/keycloak/keycloak.env`, and populate with the following example variables, customized for your own domain structure.

```bash
# Technically, this could be auto-detected, but we prefer to be prescriptive
DB_VENDOR=postgres
DB_DATABASE=keycloak
DB_ADDR=keycloak-db
DB_USER=keycloak
DB_PASSWORD=myuberpassword
KEYCLOAK_USER=admin
KEYCLOAK_PASSWORD=ilovepasswords

# This is required to run keycloak behind traefik
PROXY_ADDRESS_FORWARDING=true

# What's our hostname?
KEYCLOAK_HOSTNAME=keycloak.example.com

# Tell Postgress what user/password to create
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=myuberpassword
```

Create `/var/data/config/keycloak/keycloak-backup.env`, and populate with the following, so that your database can be backed up to the filesystem, daily:

```bash
PGHOST=keycloak-db
PGUSER=keycloak
PGPASSWORD=myuberpassword
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```

## Docker compose example

Create a docker swarm config file in docker-compose syntax (v3), something like this example:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  keycloak:
    image: jboss/keycloak
    env_file: /var/data/config/keycloak/keycloak.env
    volumes:
      - /etc/localtime:/etc/localtime:ro
    networks:
      - traefik_public
      - internal
    deploy:
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:keycloak.example.com
        - traefik.port=8080

        # traefikv2
        - "traefik.http.routers.keycloak.rule=Host(`keycloak.example.com`)"
        - "traefik.http.routers.keycloak.entrypoints=https"
        - "traefik.http.services.keycloak.loadbalancer.server.port=8080"
      
  keycloak-db:
    env_file: /var/data/config/keycloak/keycloak.env
    image: postgres:10.1
    volumes:
      - /var/data/runtime/keycloak/database:/var/lib/postgresql/data
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal

  keycloak-db-backup:
    image: postgres:10.1
    env_file: /var/data/config/keycloak/keycloak-backup.env
    volumes:
      - /var/data/keycloak/database-dump:/dump
      - /etc/localtime:/etc/localtime:ro
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        pg_dump -Fc > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.psql
        (ls -t /dump/dump*.psql|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.psql)|sort|uniq -u|xargs rm -- {}
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
        - subnet: 172.16.49.0/24
```

--8<-- "reference-networks.md"

## Running

### Launch Keycloak stack

Launch the Keycloak stack by running `docker stack deploy keycloak -c <path -to-docker-compose.yml>`

Log into your new instance at `https://YOUR-FQDN`, and login with the user/password you defined in `keycloak.env`.

### Create User

!!! question "Why are we adding a user when I have an admin user already?"
    Do you keep a spare set of house keys somewhere _other_ than your house? Do you login as `root` onto all your systems? Think of this as the same prinicple - lock the literal `admin` account away somewhere as a "password of last resort", and create a new user for your day-to-day interaction with Keycloak.

Within the "Master" realm (_no need for more realms yet_), navigate to **Manage** -> **Users**, and then click **Add User** at the top right:

![Navigating to the add user interface in Keycloak](/images/keycloak-add-user-1.png){ loading=lazy }

Populate your new user's username (it's the only mandatory field)

![Populating a username in the add user interface in Keycloak](/images/keycloak-add-user-2.png){ loading=lazy }

#### Set User Credentials

Once your user is created, to set their password, click on the "**Credentials**" tab, and procede to reset it. Set the password to non-temporary, unless you like extra work!

![Resetting a user's password in Keycloak](/images/keycloak-add-user-3.png){ loading=lazy }

## Tips

### Traefik

Keycloak can be used with Traefik in two ways..

#### Keycloak behind Traefik 

You'll notice that the docker compose example above includes labels for both Traefik v2 and Traefik v2. You obviously don't need both (*although it wont't hurt*), but make sure you update the example domain in the Traefik labels. Keycloak should work behind Traefik without any further customization.

#### Keycloak as Traefik middleware

Irrespective of whether Keycloak itself is behind Traefik, you can secure access to **other** services [behind Traefik using Keycloak][tfa-keycloak], using the [Traefik Forward Auth][tfa] middleware. Other similar middleware solutions are traefik-gatekeeper, and oauth2-proxy.

### Troubleshooting

Something didn't work? Try the following:

1. Confirm that Keycloak did, in fact, start, by looking at the state of the stack, with `docker stack ps keycloak --no-trunc`

--8<-- "recipe-footer.md"

[^1]: For more geeky {--pain--}{++fun++}, try integrating Keycloak with [OpenLDAP][openldap] for an authentication backend!
