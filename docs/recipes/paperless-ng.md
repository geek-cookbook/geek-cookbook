---
title: Run paperless-ngx under Docker
description: Easily index, search, and view archive all of your scanned dead-tree documents with Paperless NGX, under Docker, now using the linuxserver image since the fork from from paperless-ng to paperless-ngx!
recipe: Paperless NGX
---

# Paperless NGX

Paper is a nightmare. Environmental issues aside, there’s no excuse for it in the 21st century. It takes up space, collects dust, doesn’t support any form of a search feature, indexing is tedious, it’s heavy and prone to damage & loss. [^1] Paperless NGX will OCR, index, and store data about your documents so they are easy to search and view, unlike that hulking metal file cabinet you have in your office.

![Paperless-ngx Screenshot](../images/paperless-ngx.png){ loading=lazy }

!!! question "What's this fork 🍴 thing about, and is it Paperless, Paperless-NG, or Paperless-NGX?"
    It's now.. Paperless-NGX. Paperless-ngx is a fork of paperless-ng, which itself was a fork of paperless. As I understand it, the original "forker" of paperless to paperless-ng has "gone dark", and [stopped communicating](https://github.com/jonaswinkler/paperless-ng/issues/1599), so while all are hopeful that he's OK and just busy/distracted, the [community formed paperless-ngx](https://github.com/jonaswinkler/paperless-ng/issues/1632) to carry on development work under a shared responsibility model. To save some typing though, we'll just call it "Paperless", although you'll note belowe that we're using the linuxserver paperless-ngx image. (Also, if you use the automated tooling in the Premix Repo, Ansible *really* doesn't like the hypen!)

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need a folder to store a docker-compose configuration file and an associated environment file. If you're following my filesystem layout, create `/var/data/config/paperless` (*for the config*). We'll also need to create `/var/data/paperless` and a few subdirectories (*for the metadata*). Lastly, we need a directory for the database backups to reside in as well.

```bash
mkdir /var/data/config/paperless
mkdir /var/data/paperless
mkdir /var/data/paperless/consume
mkdir /var/data/paperless/data
mkdir /var/data/paperless/export
mkdir /var/data/paperless/media
mkdir /var/data/runtime/paperless/pgdata
mkdir /var/data/paperless/database-dump
```

### Create environment

To stay consistent with the other recipes, we'll create a file to store environment variables in. There's more than 1 service in this stack, but we'll only create one one environment file that will be used by the web server (more on this later).

```bash
cat << EOF > /var/data/config/paperless/paperless.env
PAPERLESS_TIME_ZONE:<timezone>
PAPERLESS_ADMIN_USER=<admin_user>
PAPERLESS_ADMIN_PASSWORD=<admin_password>
PAPERLESS_ADMIN_MAIL=<admin_email>
PAPERLESS_REDIS=redis://broker:6379
PAPERLESS_DBHOST=db
PAPERLESS_TIKA_ENABLED=1
PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000
PAPERLESS_TIKA_ENDPOINT=http://tika:9998
EOF
```

You'll need to replace some of the text in the snippet above:

* `<timezone>` - Replace with an entry from [the timezone database](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) (eg: America/New_York)
* `<admin_user>` - Username of the superuser account that will be created on first run. Without this and the *&lt;admin_password&gt;* you won't be able to log into Paperless
* `<admin_password>` - Password of the superuser account above.
* `<admin_email>` - Email address of the superuser account above.

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the following example:

--8<-- "premix-cta.md"

```yaml
version: "3.2"
services:
  
  broker:
    image: redis:6.0
    networks:
      - internal

  webserver:
    image: linuxserver/paperless-ngx
    env_file: paperless.env
    volumes:
      - /var/data/paperless/data:/usr/src/paperless/data
      - /var/data/paperless/media:/usr/src/paperless/media
      - /var/data/paperless/export:/usr/src/paperless/export
      - /var/data/paperless/consume:/usr/src/paperless/consume
    deploy:
      replicas: 1
      labels:
        # traefik
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:paperless.example.com
        - traefik.port=8000    
        - traefik.frontend.auth.forward.address=http://traefik-forward-auth:4181
        - traefik.frontend.auth.forward.authResponseHeaders=X-Forwarded-User
        - traefik.frontend.auth.forward.trustForwardHeader=true        

        # traefikv2
        - "traefik.http.routers.paperless.rule=Host(`paperless.example.com`)"
        - "traefik.http.routers.paperless.entrypoints=https"
        - "traefik.http.services.paperless.loadbalancer.server.port=8000"
        - "traefik.http.routers.paperless.middlewares=forward-auth"
    networks:
      - internal
      - traefik_public

  gotenberg:
    image: thecodingmachine/gotenberg
    environment:
      DISABLE_GOOGLE_CHROME: 1
    networks:
      - internal

  tika:
    image: apache/tika
    networks:
      - internal

  db:
    image: postgres:13
    volumes:
      - /var/data/runtime/paperless/pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: paperless
    networks:
      - internal
  
  db-backup:
    image: postgres:13
    volumes:
      - /var/data/paperless/database-dump:/dump
      - /etc/localtime:/etc/localtime:ro
    environment:
      PGHOST: db
      PGDATABASE: paperless
      PGUSER: paperless
      PGPASSWORD: paperless
      BACKUP_NUM_KEEP: 7
      BACKUP_FREQUENCY: 1d
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
        - subnet: 172.16.58.0/24 

```

You'll notice that there are several items under "services" in this stack. Let's take a look at what each one does:

* broker - Redis server that other services use to share data
* webserver - The UI that you will use to add and view documents, edit document metadata, and configure the application settings.
* gotenburg - Tool that facilitates converting MS Office documents, HTML, Markdown and other document types to PDF
* tika - The OCR engine that extracts text from image-only documents
* db - PostgreSQL database engine to store metadata for all the documents. [^2]
* db-backup - Service to dump the PostgreSQL database to a backup file on disk once per day

## Serving

Launch the paperless stack by running ```docker stack deploy paperless -c <path -to-docker-compose.yml>```. You can then log in with the username and password that you specified in the environment variables file above.

Head over to the [Paperless documentation](https://paperless-ng.readthedocs.io/en/latest) to see how to configure and use the application then revel in the fact you can now search all your scanned documents to to your heart's content.

[^1]: Taken directly from [Paperless documentation](https://paperless-ng.readthedocs.io/en/latest)
[^2]: This particular stack configuration was chosen because it includes a "real" database in PostgreSQL versus the more lightweight SQLite database. After all, if you go to the trouble of scanning and importing a pile of documents, you want to know the database is robust enough to keep your data safe.

{% include 'recipe-footer.md' %}
