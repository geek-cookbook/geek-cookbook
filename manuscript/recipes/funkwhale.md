# Funkwhale

[Funkwhale](https://funkwhale.audio) is a decentralized, federated, and open music streaming / sharing platform. Think of it as "Mastodon for music". Here's a nifty online [demo](https://demo.funkwhale.audio/) :musical_note:

![Funkwhale Screenshot](https://funkwhale.audio/img/desktop.5e79eb16.jpg)

The idea is that you run a "pod" (*just like whales, Funkwhale users gather in pods*).  A pod is a website running the Funkwhale server software. You join the network by registering an account on a pod (*sometimes called "server" or "instance"*), which will be your home.

You will be then able to interact with other people regardless of which pod they are using.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

First we create a directory to hold our funky data:

```
mkdir /var/data/funkwhale
```

### Prepare environment

Funkwhale is configured using environment variables. Create `/var/data/config/funkwhale/funkwhale.env`, by running something like this:

```bash
mkdir -p /var/data/config/funkwhale/
cat > /var/data/config/funkwhale/funkwhale.env << EOF
# Replace 'your.funkwhale.example' with your actual domain
FUNKWHALE_HOSTNAME=your.funkwhale.example
# Protocol may also be: http
FUNKWHALE_PROTOCOL=https
# This limits the upload size
NGINX_MAX_BODY_SIZE=100M
# Bind to localhost
FUNKWHALE_API_IP=127.0.0.1
# Container port you want to expose on the host
FUNKWHALE_API_PORT=5000
# Generate and store a secure secret key for your instance
DJANGO_SECRET_KEY=$(openssl rand -hex 45)
# Remove this if you expose the container directly on ports 80/443
NESTED_PROXY=1
# adapt to the pid/gid that own /var/data/funkwhale/
PUID=1000
PGID=1000
EOF
# reduce permissions on the .env file since it contains sensitive data
chmod 600 /var/data/funkwhale/funkwhale.env  
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3) (*I store all my config files as `/var/data/config/<stack name\>/<stack name\>.yml`*), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3.2" # https://docs.docker.com/compose/compose-file/compose-versioning/#version-3

services:
  funkwhale:
    image: funkwhale/all-in-one:1.0.1
    env_file: /var/data/config/funkwhale/funkwhale.env
    command: -config /linx.conf
    volumes:
      - /var/data/funkwhale/:/data/
      - /path/to/your/music/dir:/music:ro
    deploy:
      labels:
        # traefik common
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:funkwhale.example.com
        - traefik.port=8080     

        # traefikv2
        - "traefik.http.routers.linx.rule=Host(`funkwhale.example.com`)"
        - "traefik.http.routers.linx.entrypoints=https"
        - "traefik.http.services.linx.loadbalancer.server.port=5000" 
    networks:
      - traefik_public

networks:
  traefik_public:
    external: true
```

## Serving

### Scale the Whale :whale:!

Launch the Funkwhale stack by running ```docker stack deploy funkwhale -c <path -to-docker-compose.yml>```

[^1]: Since the whole purpose of media sharing is to share **publically**, and Funkwhale includes robust user authentication, this recipe doesn't employ traefik-based authentication using [Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/).
[^2]: These instructions are an opinionated simplication of the official instructions found at https://docs.funkwhale.audio/installation/docker.html
[^3]: If the funky whale is "playing your song", note that the funkwhale project is [looking for maintainers](https://blog.funkwhale.audio/~/Announcements/funkwhale-is-looking-for-new-maintainers/).

--8<-- "recipe-footer.md"