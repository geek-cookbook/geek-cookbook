hero: Huginn - A recipe for self-hosted, hackable version of IFFTT / Zapier

# Huginn

Huginn is a system for building agents that perform automated tasks for you online. They can read the web, watch for events, and take actions on your behalf. Huginn's Agents create and consume events, propagating them along a directed graph. Think of it as a hackable version of IFTTT or Zapier on your own server.

<iframe src="https://player.vimeo.com/video/61976251" width="640" height="433" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design

## Preparation

### Setup data locations

Create the location for the bind-mount of the database, so that it's persistent:

```
mkdir -p /var/data/huginn/database
```

### Create email address

Strictly speaking, you don't **have** to integrate Huginn with email. However, since we created our own mailserver stack earlier, it's worth using it to enable emails within Huginn.

```
cd /var/data/docker-mailserver/
./setup.sh email add huginn@huginn.example.com my-password-here
# Setup MX and DKIM if they don't already exist:
./setup.sh config dkim
cat config/opendkim/keys/huginn.example.com/mail.txt
```

### Prepare environment

Create /var/data/huginn/huginn.env, and populate with the following variables. Set the "INVITATION_CODE" variable if you want to require users to enter a code to sign up (protects the UI from abuse) (The full list of Huginn environment variables is available [here](https://github.com/huginn/huginn/blob/master/.env.example))

```
# For huginn/huginn - essential
SMTP_DOMAIN=your-domain-here.com
SMTP_USER_NAME=you@gmail.com
SMTP_PASSWORD=somepassword
SMTP_SERVER=your-mailserver-here.com
SMTP_PORT=587
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
INVITATION_CODE=<set an invitation code here>
POSTGRES_PORT_5432_TCP_ADDR=db
POSTGRES_PORT_5432_TCP_PORT=5432
DATABASE_USERNAME=huginn
DATABASE_PASSWORD=<database password>
DATABASE_ADAPTER=postgresql

# Optional extras for huginn/huginn, customize or append based on .env.example lined above
TWITTER_OAUTH_KEY=
TWITTER_OAUTH_SECRET=

# For postgres/postgres
POSTGRES_USER=huginn
POSTGRES_PASSWORD=<database password>
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:

  huginn:
    image: huginn/huginn
    env_file: /var/data/config/huginn/huginn.env
    volumes:
    - /etc/localtime:/etc/localtime:ro
    networks:
    - internal
    - traefik
    deploy:
      labels:
        - traefik.frontend.rule=Host:huginn.funkypenguin.co.nz
        - traefik.docker.network=traefik
        - traefik.port=3000

  db:
    env_file: /var/data/config/huginn/huginn.env
    image: postgres:latest
    volumes:
      - /var/data/runtime/huginn/database:/var/lib/postgresql/data
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal

  db-backup:
    image: postgres:latest
    env_file: /var/data/config/huginn/huginn.env
    volumes:
      - /var/data/huginn/database-dump:/dump
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
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.6.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch Huginn stack

Launch the Huginn stack by running ```docker stack deploy huginn -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. You'll need to use the "Sign Up" button, and (optionally) enter your invitation code in order to create your account.

## Chef's Notes

1. I initially considered putting an oauth proxy in front of Huginn, but since the invitation code logic prevents untrusted access, and since using a proxy would break oauth for sevices like Twitter integration, I left it out.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
