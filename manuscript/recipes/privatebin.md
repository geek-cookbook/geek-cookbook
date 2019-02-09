# PrivateBin

PrivateBin is a minimalist, open source online pastebin where the server (can) has zero knowledge of pasted data. We all need to paste data / log files somewhere when it doesn't make sense to paste it inline. With PasteBin, you can own the hosting, access, and eventual deletion of this data.

![PrivateBin Screenshot](../images/privatebin.png)

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik_public) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need a single location to bind-mount into our container, so create /var/data/privatebin, and make it world-writable (_there might be a more secure way to do this!_)

```
mkdir /var/data/privatebin
chmod 777 /var/data/privatebin/
```


### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:
  app:
    image: privatebin/nginx-fpm-alpine:1.2.1
    volumes:
      - /var/data/privatebin:/srv/data
    networks:
      - internal
      
  proxy:
    image: funkypenguin/oauth2_proxy:latest
    env_file: /var/data/privatebin/privatebin.env
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:privatebin.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=4180
    volumes:
      - /var/data/privatebin/authenticated-emails.txt:/authenticated-emails.txt
    command: |
      -cookie-secure=false
      -upstream=http://app:80
      -redirect-url=https://privatebin.example.com
      -http-address=http://0.0.0.0:4180
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.41.0/24

```


### Secure public access

What you'll quickly notice about this recipe is that the web interface is protected by an [OAuth proxy](/reference/oauth_proxy/).

Why? Because this tool is developed by a handful of volunteer developers who are focused on adding features, not necessarily implementing robust security. Most users wouldn't expose this tool directly to the internet, so the tool have rudimentary (if any) access control.

To mitigate the risk associated with public exposure of this tool (_you're on your smartphone and you want to add a movie to your watchlist, what do you do, hotshot?_), in order to gain access to the tool you'll first need to authenticate against your given OAuth provider.

To be protected by an OAuth proxy, requires unique configuration. I use github to provide my oauth, giving the tool a unique logo while I'm at it (make up your own random string for OAUTH2PROXYCOOKIE_SECRET)

For the tool, create /var/data/privatebin/privatebin.env, and set the following:

```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

Create at least /var/data/privatebin/authenticated-emails.txt, containing at least your own email address with your OAuth provider.
        
## Serving

### Launch PrivateBin stack

Launch the PrivateBin stack by running ```docker stack deploy privatebin -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**

## Chef's Notes

1. The [PrivateBin repo](https://github.com/PrivateBin/PrivateBin/blob/master/INSTALL.md) explains how to tweak configuration options, or to use a database instead of file storage, if your volume justifies it :)
2. The inclusion of PrivateBin was due to the efforts of @gkoerk in our [Discord server](http://chat.funkypenguin.co.nz). Thanks Jerry!!

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
