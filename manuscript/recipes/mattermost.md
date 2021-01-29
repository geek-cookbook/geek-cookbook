# MatterMost

Intro

![MatterMost Screenshot](../images/mattermost.png)

Details

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/mattermost:

```
mkdir -p /var/data/mattermost/{cert,config,data,logs,plugins,database-dump}
mkdir -p /var/data/runtime/mattermost/database
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

--8<-- "premix-cta.md"

```yaml
version: '3'

services:

    db:
      image: mattermost/mattermost-prod-db
      env_file: /var/data/config/mattermost/mattermost.env
      volumes:
        - /var/data/runtime/mattermost/database:/var/lib/postgresql/data
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

--8<-- "reference-networks.md"

## Serving

### Launch MatterMost stack

Launch the MatterMost stack by running ```docker stack deploy mattermost -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in mattermost.env.

--8<-- "recipe-footer.md"