hero: Kanboard - A recipe to get your personal kanban on

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

![](/images/kanboard.png)

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

Create the location for the bind-mount of the application data, so that it's persistent:

```
mkdir -p /var/data/kanboard
```

### Setup Environment

If you intend to use an [OAuth proxy](/reference/oauth_proxy/) to further secure public access to your instance, create a ```kanboard.env``` file to hold your environment variables, and populate with your OAuth provider's details (_the cookie secret you can just make up_):

```
# If you decide to protect kanboard with an oauth_proxy, complete these
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
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
    - internal
    deploy:
      labels:
        - traefik.frontend.rule=Host:kanboard.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=80

    proxy:
      image: a5huynh/oauth2_proxy
      env_file : /var/data/config/kanboard/kanboard.env
      networks:
        - internal
        - traefik_public
      deploy:
        labels:
          - traefik.frontend.rule=Host:kanboard.example.com
          - traefik.docker.network=traefik_public
          - traefik.port=4180
      volumes:
        - /var/data/config/kanboard/authenticated-emails.txt:/authenticated-emails.txt
      command: |
        -cookie-secure=false
        -upstream=http://app
        -redirect-url=https://kanboard.example.com
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
        - subnet: 172.16.8.0/24    
```

## Serving

### Launch Kanboard stack

Launch the Kanboard stack by running ```docker stack deploy kanboard -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. Default credentials are admin/admin, after which you can change (_under 'profile'_) and add more users.

[^1]: The default theme can be significantly improved by applying the [ThemePlus](https://github.com/phsteffen/kanboard-themeplus) plugin.
[^2]: Kanboard becomes more useful when you integrate in/outbound email with [MailGun](https://github.com/kanboard/plugin-mailgun), [SendGrid](https://github.com/kanboard/plugin-sendgrid), or [Postmark](https://github.com/kanboard/plugin-postmark).

--8<-- "recipe-footer.md"
