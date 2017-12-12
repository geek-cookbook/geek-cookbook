# AutoPirate

Once the cutting edge of the "internet" (pre-world-wide-web and mosiac days), Usenet is now a murky, geeky alternative to torrents for file-sharing. However, it's **cool** geeky, especially if you're into having a fully automated media platform.

A good starter for the usenet scene is https://www.reddit.com/r/usenet/. Because it's so damn complicated, a host of automated tools exist to automate the process of finding, downloading, and managing content. The tools included in this recipe are as follows:

![Autopirate Screenshot](../images/autopirate.png)

* **[SABnzbd](http://sabnzbd.org)** : downloads data from usenet servers based on .nzb definitions
* **[NZBHydra](https://github.com/theotherp/nzbhydra)** : acts as a "meta-indexer", so that your downloading tools (radarr, sonarr, etc) only need to be setup for a single indexes. Also produces interesting stats on indexers, which helps when evaluating which indexers are performing well.
* **[Sonarr](https://sonarr.tv)** : finds, downloads and manages TV shows
* **[Radarr](https://radarr.video)** : finds, downloads and manages movies
* **[Mylar](https://github.com/evilhero/mylar)** : finds, downloads and manages comic books
* **[Headphones](https://github.com/rembo10/headphones)** : finds, downloads and manages music
* **[Lazy Librarian](https://github.com/itsmegb/LazyLibrarian)** : finds, downloads and manages ebooks
* **[ombi](https://github.com/tidusjar/Ombi)** : provides an interface to request additions to a plex library using the above tools
* **[plexpy](https://github.com/JonnyWong16/plexpy)** : provides interesting stats on your plex server's usage

This recipe presents a method to combine these tools into a single swarm deployment, and make them available securely.


!!! note
    This is a **looong** recipe. It contains 18 containers, and could easily scale to more.

What you'll quickly notice about this recipe is that __every__ web interface is protected by an [OAuth proxy](/reference/oauth_proxy/).

Why? Because these tools are developed by a handful of volunteer developers who are focused on adding features, not necessarily implementing robust security. Most users wouldn't expose these tools directly to the internet, so the tools have rudimentary (if any) access control.

To mitigate the risk associated with public exposure of these tools (_you're on your smartphone and you want to add a movie to your watchlist, what do you do, hotshot?_), in order to gain access to each tool you'll first need to authenticate against your given OAuth provider.

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. Access to NZB indexers and Usenet servers
4. DNS entries configured for each of the NZB tools in this recipe that you want to use

## Preparation

### Setup data locations

We'll need a unique directories for each tool in the stack, bind-mounted into our containers, so create them upfront, in /var/data/autopirate:

```
mkdir /var/data/autopirate
cd /var/data/autopirate
mkdir -p {lazylibrarian,mylar,ombi,sonarr,radarr,headphones,plexpy,nzbhydra,sabnzbd}
```

Create a directory for the storage of your downloaded media, i.e., something like:

```
mkdir /var/data/media
```

Create a user to "own" the above directories, and note the uid and gid of the created user. You'll need to specify the UID/GID in the environment variables passed to the container (in the example below, I used 4242 - twice the meaning of life).

### Setup OAUTH access

This is tedious. Each tool (Sonarr, Radarr, etc) to be protected by an OAuth proxy, requires unique configuration. I use github to provide my oauth, giving each tool a unique logo while I'm at it.

For each tool, create /var/data/autopirate/<tool>.env, and set the following:

```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
PUID=4242
PGID=4242
```

Create at least /var/data/autopirate/authenticated-emails.txt, containing at least your own email address with your OAuth provider. If you wanted to grant access to a specific tool to other users, you'd need a unique authenticated-emails-<tool>.txt which included both normal email address as well as any addresses to be granted tool-specific access.

### Setup components

#### Stack basics

**Start** with a swarm config file in docker-compose syntax, like this:

````
version: '3'

services:
````

And **end** with a stanza like this:

````
networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.11.0/24
````

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.

What comes next, goes inbetween...

#### Sabnzbd

````
sabnzbd:
  image: linuxserver/sabnzbd:latest
  volumes:
   - /var/data/autopirate/sabnzbd:/config
   - /var/data/media:/media
  networks:
  - traefik_public

sabnzbd_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/sabnzbd.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:sabnzbd.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://sabnzbd:8080
    -redirect-url=https://sabnzbd.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

#### Lazy Librarian

If you plan to use Lazy Librarian, add the following to your swarm config file:

````
lazylibrarian:
  image: linuxserver/lazylibrarian:latest
  env_file : /var/data/config/autopirate/lazylibrarian.env
  volumes:
   - /var/data/autopirate/lazylibrarian:/config
   - /var/data/media:/media
  networks:
  - traefik_public

lazylibrarian_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/lazylibrarian.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:lazylibrarian.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://lazylibrarian:5299
    -redirect-url=https://lazylibrarian.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍



#### Mylar

If you plan to use Mylar, add the following to your swarm config file:

````
mylar:
  image: linuxserver/mylar:latest
  env_file : /var/data/config/autopirate/mylar.env
  volumes:
   - /var/data/autopirate/mylar:/config
   - /var/data/media:/media
  networks:
  - traefik_public
  -
mylar_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/mylar.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:mylar.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://mylar:8090
    -redirect-url=https://mylar.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


#### Ombi

If you plan to use Ombi, add the following to your swarm config file:

````
ombi:
  image: linuxserver/ombi:latest
  env_file : /var/data/config/autopirate/ombi.env
  volumes:
   - /var/data/autopirate/ombi:/config
  networks:
  - traefik_public

ombi_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/ombi.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:ombi.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://ombi:3579
    -redirect-url=https://ombi.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


#### Headphones

If you plan to use Headphones, add the following to your swarm config file:

````
headphones:
  image: linuxserver/headphones:latest
  env_file : /var/data/config/autopirate/headphones.env
  volumes:
   - /var/data/autopirate/headphones:/config
   - /var/data/media:/media
  networks:
  - traefik_public

headphones_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/headphones.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:headphones.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://headphones:8181
    -redirect-url=https://headphones.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


#### Plexpy

If you plan to use Plexpy, add the following to your swarm config file:

````
plexpy:
  image: linuxserver/plexpy:latest
  env_file : /var/data/config/autopirate/plexpy.env
  volumes:
   - /var/data/autopirate/plexpy:/config
  networks:
  - traefik_public

plexpy_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/plexpy.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:plexpy.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://plexpy:8181
    -redirect-url=https://plexpy.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


#### Radarr

If you plan to use Radarr, add the following to your swarm config file:

````
radarr:
  image: linuxserver/radarr:latest
  env_file : /var/data/config/autopirate/radarr.env
  volumes:
   - /var/data/autopirate/radarr:/config
   - /var/data/media:/media
  networks:
  - traefik_public

radarr_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/radarr.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:radarr.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://radarr:7878
    -redirect-url=https://radarr.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


#### Sonarr

If you plan to use Sonarr, add the following to your swarm config file:

````
sonarr:
  image: linuxserver/sonarr:latest
  env_file : /var/data/config/autopirate/sonarr.env
  volumes:
   - /var/data/autopirate/sonarr:/config
   - /var/data/media:/media
  networks:
  - traefik_public

sonarr_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/sonarr.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:sonarr.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://sonarr:8989
    -redirect-url=https://sonarr.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍



#### NZBHydra

If you plan to use NZBHydra, add the following to your swarm config file:

````
nzbhydra:
  image: linuxserver/hydra:latest
  env_file : /var/data/config/autopirate/nzbhydra.env
  volumes:
   - /var/data/autopirate/nzbhydra:/config
  networks:
  - traefik_public

nzbhydra_proxy:
  image: zappi/oauth2_proxy
  env_file : /var/data/config/autopirate/nzbhydra.env
  networks:
    - internal
    - traefik_public
  deploy:
    labels:
      - traefik.frontend.rule=Host:nzbhydra.example.com
      - traefik.docker.network=traefik_public
      - traefik.port=4180
  volumes:
    - /var/data/config/autopirate/authenticated-emails.txt:/authenticated-emails.txt
  command: |
    -cookie-secure=false
    -upstream=http://nzbhydra:5075
    -redirect-url=https://nzbhydra.example.com
    -http-address=http://0.0.0.0:4180
    -email-domain=example.com
    -provider=github
    -authenticated-emails-file=/authenticated-emails.txt
````

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


## Serving

### Launch Autopirate stack

Launch the AutoPirate stack by running ```docker stack deploy autopirate -c <path -to-docker-compose.yml>```

Confirm the container status by running "docker stack ps autopirate", and wait for all containers to enter the "Running" state.

Log into each of your new tools at its respective HTTPS URL. You'll be prompted to authenticate against your OAuth provider, and upon success, redirected to the tool's UI.

## Chef's Notes

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.
