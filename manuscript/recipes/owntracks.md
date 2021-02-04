# OwnTracks

[OwnTracks](https://owntracks.org/) allows you to keep track of your own location. You can build your private location diary or share it with your family and friends. OwnTracks is open-source and uses open protocols for communication so you can be sure your data stays secure and private.

![OwnTracks Screenshot](../images/owntracks.png)

Using a smartphone app, OwnTracks allows you to collect and analyse your own location data **without** sharing this data with a cloud provider (_i.e. Apple, Google_). Potential use cases are:

* Sharing family locations without relying on Apple Find-My-friends
* Performing automated actions in [HomeAssistant](/recipes/homeassistant/) when you arrive/leave home

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need a directory so store OwnTracks' data , so create  ```/var/data/owntracks```:

```
mkdir /var/data/owntracks
```

### Prepare environment

Create owntracks.env, and populate with the following variables

```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=

OTR_USER=recorder
OTR_PASS=yourpassword
OTR_HOST=owntracks.example.com
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3.0"

services:
    owntracks-app:
      image: funkypenguin/owntracks
      env_file : /var/data/config/owntracks/owntracks.env
      volumes:
        - /var/data/owntracks:/owntracks
      networks:
        - internal
      ports:
        - 1883:1883
        - 8883:8883
        - 8083:8083

    owntracks-proxy:
      image: a5huynh/oauth2_proxy
      env_file : /var/data/config/owntracks/owntracks.env
      networks:
        - internal
        - traefik_public
      deploy:
        labels:
              - traefik.frontend.rule=Host:owntracks.example.com
          - traefik.docker.network=traefik_public
          - traefik.port=4180
      volumes:
        - /var/data/config/owntracks/authenticated-emails.txt:/authenticated-emails.txt
      command: |
        -cookie-secure=false
        -upstream=http://owntracks-app:8083
        -redirect-url=https://owntracks.example.com
        -http-address=http://0.0.0.0:4180
        -email-domain=example.com
        -provider=github
        -authenticated-emails-file=/authenticated-emails.txt

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.15.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch OwnTracks stack

Launch the OwnTracks stack by running ```docker stack deploy owntracks -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

[^1]: If you wanted to expose the OwnTracks Web UI directly, you could remove the oauth2_proxy from the design, and move the traefik-related labels directly to the wekan container. You'd also need to add the traefik network to the owntracks container.
[^2]: I'm using my own image rather than owntracks/recorderd, because of a [potentially swarm-breaking bug](https://github.com/owntracks/recorderd/issues/14) I found in the official container. If this gets resolved (_or if I was mistaken_) I'll update the recipe accordingly.
[^3]: By default, you'll get a fully accessible, unprotected MQTT broker. This may not be suitable for public exposure, so you'll want to look into securing mosquitto with TLS and ACLs.

--8<-- "recipe-footer.md"