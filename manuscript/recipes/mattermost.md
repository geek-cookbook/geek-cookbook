# MatterMost

Intro

![MatterMost Screenshot](../images/mattermost.jpg)

Details

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik_public) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/mattermost:

```
mkdir -p /var/data/mattermost/{cert,config,data,logs,plugins,database-dump}
mkdir -p /var/data/realtime/mattermost/database
```

### Prepare environment

Create mattermost.env, and populate with the following variables
```
POSTGRES_USER=mmuser
POSTGRES_PASSWORD=mmuser_password
POSTGRES_DB=mattermost
MM_USERNAME=mmuser
MM_PASSWORD=mmuser_password
MM_DBNAME=mattermost
```

Now create mattermost-backup.env, and populate with the following variables:
```
PGHOST=db
PGUSER=mmuser
PGPASSWORD=mmuser_password
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

    db:
      image: mattermost/mattermost-prod-db
      env_file: /var/data/config/mattermost/mattermost.env
      volumes:
        - /var/data/realtime/mattermost/database:/var/lib/postgresql/data
      networks:
        - internal

    app:
      image: mattermost/mattermost-team-edition
      env_file: /var/data/config/mattermost/mattermost.env      
      volumes:
        - /var/data/mattermost/config:/mattermost/config:rw
        - /var/data/mattermost/data:/mattermost/data:rw
        - /var/data/mattermost/logs:/mattermost/logs:rw
        - /var/data/mattermost/plugins:/mattermost/plugins:rw

    db-backup:
      image: mattermost/mattermost-prod-db
      env_file: /var/data/config/mattermost/mattermost-backup.env
      volumes:
        - /var/data/mattermost/database-dump:/dump
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
        - subnet: 172.16.40.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch MatterMost stack

Launch the MatterMost stack by running ```docker stack deploy mattermost -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

## Chef's Notes

1. If you wanted to expose the Wekan UI directly, you could remove the oauth2_proxy from the design, and move the traefik_public-related labels directly to the wekan container. You'd also need to add the traefik_public network to the wekan container.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
