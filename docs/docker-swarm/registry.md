---
title: Setup pull through Docker registry / cache
description: You may not _want_ your cluster to be pulling multiple copies of images from public registries, especially if rate-limits (hello, Docker Hub!) are a concern. Here's how you setup your own "pull through cache" registry.
---
# Create Docker "pull through" registry cache

Although we now have shared storage for our persistent container data, our docker nodes don't share any other docker data, such as container images. This results in an inefficiency - every node which participates in the swarm will, at some point, need the docker image for every container deployed in the swarm.

When dealing with large container (looking at you, GitLab!), this can result in several gigabytes of wasted bandwidth per-node, and long delays when restarting containers on an alternate node. (_It also wastes disk space on each node, but we'll get to that in the next section_)

The solution is to run an official Docker registry container as a ["pull-through" cache, or "registry mirror"](https://docs.docker.com/registry/recipes/mirror/). By using our persistent storage for the registry cache, we can ensure we have a single copy of all the containers we've pulled at least once. After the first pull, any subsequent pulls from our nodes will use the cached version from our registry mirror. As a result, services are available more quickly when restarting container nodes, and we can be more aggressive about cleaning up unused containers on our nodes (*more later*)

The registry mirror runs as a swarm stack, using a simple docker-compose.yml. Customize **your mirror FQDN** below, so that Traefik will generate the appropriate LetsEncrypt certificates for it, and make it available via HTTPS.

## Requirements

!!! summary "Ingredients"

    * [ ] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [ ] [Traefik](/docker-swarm/traefik/) configured per design
    * [ ] DNS entry for the hostname you intend to use, pointed to your [keepalived](/docker-swarm/keepalived/) IP

## Configuration

Create `/var/data/config/registry/registry.yml` as per the following docker-compose example:

```yaml
version: "3"

services:

  registry-mirror:
    image: registry:2
    networks:
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:<your mirror FQDN>
        - traefik.docker.network=traefik_public
        - traefik.port=5000
    ports:
      - 5000:5000
    volumes:
      - /var/data/registry/registry-mirror-data:/var/lib/registry
      - /var/data/registry/registry-mirror-config.yml:/etc/docker/registry/config.yml

networks:
  traefik_public:
    external: true
```

!!! note "Unencrypted registry"
We create this registry without consideration for SSL, which will fail if we attempt to use the registry directly. However, we're going to use the HTTPS-proxied version via [Traefik][traefik], leveraging Traefik to manage the LetsEncrypt certificates required.

Create the configuration for the actual registry in `/var/data/registry/registry-mirror-config.yml` as per the following example:

```yaml
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
  remoteurl: https://registry-1.docker.io
```

## Running

### Launch Docker registry stack

Launch the registry stack by running `docker stack deploy registry -c <path-to-docker-compose.yml>`

### Enable Docker registry mirror

To tell docker to use the registry mirror, edit `/etc/docker-latest/daemon.json` [^1] on each node, and change from:

```json
{
    "log-driver": "journald",
    "signature-verification": false
}
```

To:

```json
{
    "log-driver": "journald",
    "signature-verification": false,
    "registry-mirrors": ["https://<your registry mirror FQDN>"]
}
```

Then restart docker itself, by running `systemctl restart docker`

[^1]: Note the extra comma required after "false" above

{% include 'recipe-footer.md' %}
