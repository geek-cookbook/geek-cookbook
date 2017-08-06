# Huginn

Huginn is a system for building agents that perform automated tasks for you online. They can read the web, watch for events, and take actions on your behalf. Huginn's Agents create and consume events, propagating them along a directed graph. Think of it as a hackable version of IFTTT or Zapier on your own server.

<iframe src="https://player.vimeo.com/video/61976251" width="640" height="433" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

!!! note
    Since the Huginn UI doesn't include any authentication, we put it behind an [oauth2 proxy](/reference/oauth_proxy/), so that in order to gain access to the Huginn UI at all, oauth2 authentication (to GitHub, GitLab, Google, etc) must have already occurred.

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. OAuth key and secret unique to Huginn (See )

## Preparation

### Setup data locations

Create the location for the bind-mount of the database, so that it's persistent:

```
mkdir -p /var/data/huginn/database
```

### Create email address

Strictly speaking, you don't have to integrate Huginn with email. However, since we created our own mailserver stack earlier, it's worth using it to enable emails within Huginn.

```
cd /var/data/docker-mailserver/
./setup.sh email add huginn@huginn.example.com my-password-here
# Setup MX and DKIM if they don't already exist:
./setup.sh config dkim
cat config/opendkim/keys/huginn.example.com/mail.txt
```

### Setup OAuth access

https://huginn.funkypenguin.co.nz/oauth2/callback


### Prepare environment

Create /var/data/huginn/huginn.env, and populate with the following variables. The full list of Huginn environment variables is available at https://github.com/huginn/huginn/blob/master/.env.example

```
# For huginn/huginn
SMTP_DOMAIN=your-domain-here.com
SMTP_USER_NAME=you@gmail.com
SMTP_PASSWORD=somepassword
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# For zappi/oauth2_proxy
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=

# For postgres/postgres
DB_USER=huginn
DB_PASS=<your db password>
DB_NAME=huginn
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

```
version: '3'

services:

  huginn:
    image: huginn/huginn
    env_file: /var/data/huginn/huginn.env
    networks:
    - internal   

  db:
    image: postgres:latest
    volumes:
    - /var/data/huginn/database:/var/lib/postgresql/data
    networks:
    - internal

  proxy:
    image: zappi/oauth2_proxy
    env_file: /var/data/huginn/huginn.env
    networks:
      - traefik
      - internal
    volumes:
      - /var/data/oauth_proxy/authenticated-emails.txt:/authenticated-emails.txt
    deploy:
      labels:
        - traefik.frontend.rule=Host:huginn.example.com
        - traefik.docker.network=traefik
        - traefik.port=4180
    command: |
      -cookie-secure=false
      -upstream=http://huginn:80
      -redirect-url=https://huginn.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt      

networks:
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.6.0/24
```

!!! tip
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch Huginn stack

Launch the Huginn stack by running ```docker stack deploy huginn -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

## Chef's Notes

1. If you wanted to expose the Wekan UI directly, you could remove the oauth2_proxy from the design, and move the traefik-related labels directly to the wekan container. You'd also need to add the traefik network to the wekan container.
