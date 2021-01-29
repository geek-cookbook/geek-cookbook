# Wekan

Wekan is an open-source kanban board which allows a card-based task and to-do management, similar to tools like WorkFlowy or Trello.

![Wekan Screenshot](../images/wekan.jpg)

Wekan allows to create Boards, on which Cards can be moved around between a number of Columns. Boards can have many members, allowing for easy collaboration, just add everyone that should be able to work with you on the board to it, and you are good to go! You can assign colored Labels to cards to facilitate grouping and filtering, additionally you can add members to a card, for example to assign a task to someone.

There's a [video](https://www.youtube.com/watch?v=N3iMLwCNOro) of the developer showing off the app, as well as a f[unctional demo](https://wekan.indie.host/b/t2YaGmyXgNkppcFBq/wekan-fork-roadmap).

!!! note
    For added privacy, this design secures wekan behind an [oauth2 proxy](/reference/oauth_proxy/), so that in order to gain access to the wekan UI at all, oauth2 authentication (_to GitHub, GitLab, Google, etc_) must have already occurred.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/wekan:

```
mkdir /var/data/wekan
cd /var/data/wekan
mkdir -p {wekan-db,wekan-db-dump}
```

### Prepare environment

You'll need to know the following:

1. Choose an oauth provider, and obtain a client ID and secret
2. Create wekan.env, and populate with the following variables

```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
MONGO_URL=mongodb://wekandb:27017/wekan
ROOT_URL=https://wekan.example.com
MAIL_URL=smtp://wekan@wekan.example.com:password@mail.example.com:587/
MAIL_FROM="Wekan <wekan@wekan.example.com>"

# Mongodb specific database dump details
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:

  wekandb:
    image: mongo:latest
    command: mongod --smallfiles --oplogSize 128
    networks:
      - internal
    volumes:
      - /var/data/runtime/wekan/database:/data/db
      - /var/data/wekan/database-dump:/dump

  proxy:
    image: a5huynh/oauth2_proxy
    env_file: /var/data/config/wekan/wekan.env
    networks:
      - traefik
      - internal
    volumes:
      - /var/data/oauth_proxy/authenticated-emails.txt:/authenticated-emails.txt
    deploy:
      labels:
        - traefik.frontend.rule=Host:wekan.example.com
        - traefik.docker.network=traefik
        - traefik.port=4180
    command: |
      -cookie-secure=false
      -upstream=http://wekan:80
      -redirect-url=https://wekan.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt

  wekan:
    image: wekanteam/wekan:latest
    networks:
      - internal
    env_file: /var/data/config/wekan/wekan.env

  db-backup:
    image: mongo:latest
    env_file : /var/data/config/wekan/wekan.env
    volumes:
      - /var/data/wekan/database-dump:/dump
      - /etc/localtime:/etc/localtime:ro
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        mongodump -h db --gzip --archive=/dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.mongo.gz
        (ls -t /dump/dump*.mongo.gz|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.mongo.gz)|sort|uniq -u|xargs rm -- {}
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
        - subnet: 172.16.3.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Wekan stack

Launch the Wekan stack by running ```docker stack deploy wekan -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

[^1]: If you wanted to expose the Wekan UI directly, you could remove the oauth2_proxy from the design, and move the traefik-related labels directly to the wekan container. You'd also need to add the traefik network to the wekan container.

--8<-- "recipe-footer.md"