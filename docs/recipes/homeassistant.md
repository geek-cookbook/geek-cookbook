---
description: Assist your home automation
recipe: Home Assistant
---

# Home Assistant

Home Assistant is a home automation platform written in Python, with extensive support for 3rd-party home-automation platforms including Xaomi, Phillips Hue, and a [bazillion](https://home-assistant.io/components/) others.

![Home Assistant Screenshot](../images/homeassistant.png){ loading=lazy }

This recipe combines the [extensibility](https://home-assistant.io/components/) of [Home Assistant](https://home-assistant.io/) with the flexibility of [InfluxDB](https://docs.influxdata.com/influxdb/v1.4/) (_for time series data store_) and [Grafana](https://grafana.com/) (_for **beautiful** visualisation of that data_).

## {{ page.meta.recipe }} Requirements

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/homeassistant:

```bash
mkdir /var/data/homeassistant
cd /var/data/homeassistant
mkdir -p {homeassistant,grafana,influxdb-backup}
```

Now create a directory for the influxdb realtime data:

```bash
mkdir /var/data/runtime/homeassistant/influxdb
```

### Prepare {{ page.meta.recipe }} environment

Create /var/data/config/homeassistant/grafana.env, and populate with the following - this is to enable grafana to work with oauth2_proxy without requiring an additional level of authentication:

```bash
GF_AUTH_BASIC_ENABLED=false
```

### {{ page.meta.recipe }} Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like the example below:

--8<-- "premix-cta.md"

```yaml
version: "3"

services:
    influxdb:
      image: influxdb
      networks:
        - internal
      volumes:
        - /var/data/runtime/homeassistant/influxdb:/var/lib/influxdb
        - /etc/localtime:/etc/localtime:ro

    homeassistant:
      image: homeassistant/home-assistant
      dns_search: hq.example.com
      volumes:
        - /var/data/homeassistant/homeassistant:/config
        - /etc/localtime:/etc/localtime:ro
      deploy:
        labels:
          # traefik common
          - traefik.enable=true
          - traefik.docker.network=traefik_public

          # traefikv1
          - traefik.frontend.rule=Host:homeassistant.example.com
          - traefik.port=8123     

          # traefikv2
          - "traefik.http.routers.homeassistant.rule=Host(`homeassistant.example.com`)"
          - "traefik.http.services.homeassistant.loadbalancer.server.port=8123"
          - "traefik.enable=true"
      networks:
        - traefik_public
        - internal
      ports:
        - 8123:8123

    grafana-app:
      image: grafana/grafana
      env_file : /var/data/config/homeassistant/grafana.env
      volumes:
        - /var/data/homeassistant/grafana:/var/lib/grafana
        - /etc/localtime:/etc/localtime:ro
      networks:
        - internal
        - traefik_public
      deploy:
        labels:
          # traefik common
          - traefik.enable=true
          - traefik.docker.network=traefik_public

          # traefikv1
          - traefik.frontend.rule=Host:grafana.example.com
          - traefik.port=3000     

          # traefikv2
          - "traefik.http.routers.grafana.rule=Host(`grafana.example.com`)"
          - "traefik.http.services.grafana.loadbalancer.server.port=3000"
          - "traefik.enable=true"

          # Remove if you wish to access the URL directly
          - "traefik.http.routers.grafana.middlewares=forward-auth@file"

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.13.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Home Assistant stack

Launch the Home Assistant stack by running ```docker stack deploy homeassistant -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, the password you created in configuration.yml as "frontend - api_key". Then setup a bunch of sensors, and log into <https://grafana>.**YOUR FQDN** and create some beautiful graphs :)

[^1]: I **tried** to protect Home Assistant using [oauth2_proxy](/reference/oauth_proxy/), but HA is incompatible with the websockets implementation used by Home Assistant. Until this can be fixed, I suggest that geeks set frontend: api_key to a long and complex string, and rely on this to prevent malevolent internet miscreants from turning their lights on at 2am!

{% include 'recipe-footer.md' %}
