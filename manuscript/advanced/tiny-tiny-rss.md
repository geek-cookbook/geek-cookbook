
# Introduction

[Tiny Tiny RSS][ttrss] is a self-hosted, AJAX-based RSS reader, which rose to popularity as a replacement for Google Reader. It supports advanced features, such as:

* Plugins and themeing in a drop-in fashion
* Filtering (discard all articles with title matching "trump")
* Sharing articles via a unique public URL/feed

Tiny Tiny RSS requires a database and a webserver - this recipe provides both using docker, exposed to the world via LetsEncrypt.

# Ingredients

**Required**

1. Webserver (nginx container)
2. Database (postgresql container)
3. TTRSS (ttrss container)
3. Nginx reverse proxy with LetsEncrypt


**Optional**

1. Email server (if you want to email articles from TTRSS)

# Preparation

**Setup filesystem location**

I setup a directory for the ttrss data, at /data/ttrss.

I created docker-compose.yml, as follows:

```
rproxy:
  image: nginx:1.13-alpine
  ports:
    - "34804:80"
  environment:
    - DOMAIN_NAME=ttrss.funkypenguin.co.nz
    - VIRTUAL_HOST=ttrss.funkypenguin.co.nz
    - LETSENCRYPT_HOST=ttrss.funkypenguin.co.nz
    - LETSENCRYPT_EMAIL=davidy@funkypenguin.co.nz
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf:ro
  volumes_from:
    - ttrss
  links:
    - ttrss:ttrss

ttrss:
  image: tkaefer/docker-ttrss
  restart: always
  links:
    - postgres:database
  environment:
    - DB_USER=ttrss
    - DB_PASS=uVL53xfmJxW
    - SELF_URL_PATH=https://ttrss.funkypenguin.co.nz
  volumes:
    - ./plugins.local:/var/www/plugins.local
    - ./themes.local:/var/www/themes.local
    - ./reader:/var/www/reader

postgres:
  image: postgres:latest
  volumes:
    - /srv/ssd-data/ttrss/db:/var/lib/postgresql/data
  restart: always
  environment:
    - POSTGRES_USER=ttrss
    - POSTGRES_PASSWORD=uVL53xfmJxW

gmailsmtp:
  image: softinnov/gmailsmtp
  restart: always
  environment:
    - user=davidy@funkypenguin.co.nz
    - pass=eqknehqflfbufzbh
    - DOMAIN_NAME=gmailsmtp.funkypenguin.co.nz
```

Run ```docker-compose up``` in the same directory, and watch the output. PostgreSQL container will create the "ttrss" database, and ttrss will start using it.


# Login to UI

Log into https://\<your VIRTUALHOST\>. Default user is "admin" and password is "password"

# Optional - Enable af_psql_trgm plugin for similar post detection

One of the native plugins enables the detection of "similar" articles. This requires the pg_trgm extension enabled in your database.

From the working directory, use ```docker exec``` to get a shell within your postgres container, and run "postgres" as the postgres user:
```
[root@kvm nginx]# docker exec -it ttrss_postgres_1 /bin/sh
# su - postgres
No directory, logging in with HOME=/
$ psql
psql (9.6.3)
Type "help" for help.
```

Add the trgm extension to your ttrss database:
```
postgres=# \c ttrss
You are now connected to database "ttrss" as user "postgres".
ttrss=# CREATE EXTENSION pg_trgm;
CREATE EXTENSION
ttrss=# \q
```

[ttrss]:https://tt-rss.org/
