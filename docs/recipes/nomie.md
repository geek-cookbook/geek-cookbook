---
title: Quantify your self using Nomie 6 in Docker Swarm with CouchDB
description: How to use Nomie 6 to "life-track" yourself, deployed in Docker Swarm
status: new
recipe: Nomie
---

# Nomie in Docker Swarm with CouchDB

I've long been a fan of [Nomie](https://open-nomie.github.io/), a super fast, and super-private way to journal, collect your life's data, and reflect on your life's direction.

![Nomie screenshot](/images/nomie.png){ loading=lazy }

I think I originally stumbled across at [r/quantifiedself](https://www.reddit.com/r/QuantifiedSelf/). At the time I was unhappy in my DayJob(tm), and wanted a way to quantify to my boss just how unproductive a day of disruptions was (*in the end I used a spreadsheet!*). Nomie 2 was an iOS app, IIRC.

I've dabbled in it since v3, but never found the motivation and the discipline to actually keep track, and have noted over the years how the developer discontinued it, and then, like a true artist, restarted a fresh design to keep his baby going!

[Brandon Corbin](https://brandons.app/) has been passionately developing Nomie for 8+ years, at one point [walking away](https://www.reddit.com/r/nomie/comments/7cyi01/this_feels_like_the_end/), and then 8 months later, unable to help himself, [diving right back](https://www.reddit.com/r/nomie/comments/7hl2th/this_feels_like_the_beginning/) in with what would eventually become [Nomie 3](https://nomie.app/release/3.0)!

The latest version (Nomie 6) which offered a paid cloud hosting / sync service, shut down in Feb 2023. There's a [heartfelt post](https://nomie.app/#more) providing context and alternatives. Brandon open-sourced all the code, so one of the geekier alternatives, buyoued by the still-passionate community of users, is to run your own Nomie instance.

!!! question "It's a PWA with local storage, why self-host at all?"
    Yes, you **could** just use <https://open-nomie.github.io/>, and since the PWA stores your data in your local browser store anyway, you'd get all the functionality without having to deploy a thing. However, if you want to use Nomie from **multiple browsers**, (*i.e., your phone **and** your desktop*), you'll need a way to sync the data, which, in this case, requires your own CouchDB instance. And if you're going to self-host CouchDB, you may as well self-host the PWA too!

    To this end, in this recipe, I'll assume we want CouchDB syncing (*after all, who only uses one device these days?*)

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

Create the location for the bind-mount of the application data, so that it's persistent:

```bash
mkdir -p /var/data/nomie
```

### Setup environment

Create `/var/data/config/nomie/nomie.env` as per the following example (*set your CouchDB credentials to something secure, these enable admin access to wherever CouchDB is exposed*):

```bash title="/var/data/config/nomie/nomie.env"
COUCHDB_USER=mycouchuser
COUCHDB_PASSWORD=mycouchpass
```

### Setup CouchDB for CORS

This gets a little tricker than the standard recipe, where a frontend talks to a backend database. Since Nomie is a PWA, and stores data in the browser cache, CouchDB needs to be accessible to your web browser, so that the PWA can call it directly. This means (a) it's important to secure properly, and (b) you need to explicitly permit your Nomie site to call your CouchDB URL via CORS headers.

Create `/var/data/config/nomie/couchdb.ini` per the example below, being sure to use the intended FQDN of your Nomie instance for the cors origin (*don't try to put comments after this line using a `#`, it doesn't work, ask me how I know!*)

```bash title="/var/data/config/nomie/couchdb.ini"
[HTTPD]
enable_cors = true

[chttpd]
enable_cors = true

[cors]
origins = https://nomie.example.com
credentials = true
methods = GET, PUT, POST, HEAD, DELETE
headers = accept, authorization, content-type, origin, referer, x-csrf-token
```

### Setup Nomie Docker config

Finally, create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/nomie/nomie.yml"
version: "3.2" # https://docs.docker.com/compose/compose-file/compose-versioning/#version-3

services:
  nomie:
    image: ghcr.io/qcasey/nomie6-oss:master

    deploy:
      labels:
        # traefik common
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"
        - "traefik.http.routers.nomie.rule=Host(`nomie.example.com`)"
        - "traefik.http.routers.nomie.entrypoints=https"
        - "traefik.http.services.nomie.loadbalancer.server.port=80" 
    networks:
      - traefik_public

  couchdb:
    env_file: /var/data/config/nomie/nomie.env  
    image: couchdb:3
    deploy:
      labels:
        # traefik common
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"
        - "traefik.http.routers.nomiedb.rule=Host(`nomiedb.example.com`)"
        - "traefik.http.routers.nomiedb.entrypoints=https"
        - "traefik.http.services.nomiedb.loadbalancer.server.port=5984"       
    volumes:
      - /var/data/nomie:/opt/couchdb/data
      - /var/data/config/nomie/couchdb.ini:/opt/couchdb/etc/local.d/docker.ini      
    networks:
      - traefik_public

networks:
  traefik_public:
    external: true
```

## Serving

### Launch Nomie PWA

Launch the Nomie stack by running ```docker stack deploy nomie -c <path -to-docker-compose.yml>```

You should now be able to access the PWA at the URL you chose - at this point, you have the equivalent to <https://open-nomie.github.io/>, but let's go a bit further, and setup multi-device syncing...

## Setup CouchDB

### Initialize CouchDB

CouchDB doesn't come setup (*because the Docker image has no way of knowing whether it's a single node, or a shard of a larger cluster*), so we need to set it up. Point your browser at `https://<fqdn-to-your-couchdb-instance>/_utils/#setup/singlenode`, and initialize the "cluster" as follows:

![Initialize CouchDB](/images/nomie_initialize_couchdb.png){ loading=lazy }

After creating the cluster, ignore the offer to replicate data - for our purposes, a single instance configured for production usage as an "unknown state node" is quite ok!

### Create database

Using the UI, navigate to the "database" icon, and click `Create Database`. Name your database (*I used "nomie"*):

![Create Nomie database](/images/nomie_create_database.png){ loading=lazy }

### Set database permissions

Having created the database, navigate to `Permissions`, and under "Members", add a user named `nomie`:

![Set Nomie database permissions](/images/nomie_set_permissions.png){ loading=lazy }

### Create database user

Users in CouchDB are "documents". (*everything is a document!*)

We've given permission to the database to a `nomie` user, but we haven't yet created that user. Use the UI to navigate to the `_users` database, and click on `Create Document`. A basic JSON string is populated for you, with a random `_id` value. Overwrite this string with a variation of the object below, and click `Create Document`.

```json
{
  "_id": "org.couchdb.user:nomie",
  "name": "nomie",
  "type": "user",
  "roles": [],
  "password": "nomnomnom"
}
```

That's it, you created a CouchDB user!

!!! tip
    If you change the name of the user from `nomie`, you must also change the value of `_id` to `org.couchdb.user:<whatever-name-you-chose>`

### Configure Nomie for CouchDB

In the Nomie PWA, navigate to `More`, and enter the CouchDB settings, as illustrated below:

![Set Nomie database permissions](/images/nomie_configure_couchdb.png){ loading=lazy }

If Nomie confirms success, and asks you to save the connection, then you've successfully connected Nomie to your CouchDB.

Repeat this on every **other** device/browser[^1] with which you intend to use to access your synced life data!

[^1]: If you're feeling like an extra challenge, there's [a way to log your Nomie trackables from your Apple Watch](https://iosexample.com/apple-watch-app-which-enables-logging-to-nomie/)!

## Summary

What have we achieved? We have our own instance of Nomie, syncing multi-device access to our own CouchDB. Data persists in your browser, and synced CouchDB data is stored to `/var/data/nomie` (*which can be safely backed-up, if it's a standalone CouchDB instance*).

!!! summary "Summary"
    Created:

    * [X] Our own Nomie instance, synced with own own CouchDB for multi-device access. Finally, nobody else will be able to tell how much you poop! :poo:

--8<-- "recipe-footer.md"
