---
title: How to run Kanboard using Docker
description: Run Kanboard with Docker to get your personal kanban on!
---

# Kanboard

Kanboard is a Kanban tool, developed by [Frédéric Guillot](https://github.com/fguillot). (_Who also happens to be the developer of my favorite RSS reader, [Miniflux](/recipes/miniflux/)_)

Features include:

* Visualize your work
* Limit your work in progress to be more efficient
* Customize your boards according to your business activities
* Multiple projects with the ability to drag and drop tasks
* Reports and analytics
* Fast and simple to use
* Access from anywhere with a modern browser
* Plugins and integrations with external services
* Free, open source and self-hosted
* Super simple installation

![Kanboard screenshot](/images/kanboard.png){ loading=lazy }

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

Create the location for the bind-mount of the application data, so that it's persistent:

```bash
mkdir -p /var/data/kanboard
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  kanboard:
    image: kanboard/kanboard
    volumes:
     - /var/data/kanboard:/var/www/app/
    networks:
      - traefik_public
    deploy:
      labels:
        # traefik common
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:kanboard.example.com
        - traefik.port=80     

        # traefikv2
        - "traefik.http.routers.kanboard.rule=Host(`kanboard.example.com`)"
        - "traefik.http.services.kanboard.loadbalancer.server.port=80"
        - "traefik.enable=true"

networks:
  traefik_public:
    external: true
```

## Serving

### Launch Kanboard stack

Launch the Kanboard stack by running ```docker stack deploy kanboard -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. Default credentials are admin/admin, after which you can change (_under 'profile'_) and add more users.

[^1]: The default theme can be significantly improved by applying the [ThemePlus](https://github.com/phsteffen/kanboard-themeplus) plugin.
[^2]: Kanboard becomes more useful when you integrate in/outbound email with [MailGun](https://github.com/kanboard/plugin-mailgun), [SendGrid](https://github.com/kanboard/plugin-sendgrid), or [Postmark](https://github.com/kanboard/plugin-postmark).

--8<-- "recipe-footer.md"
