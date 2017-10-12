# Docker Swarm Mode

For truly highly-available services with Docker containers, we need an orchestration system. Docker Swarm (as defined at 1.13) is the simplest way to achieve redundancy, such that a single docker host could be turned off, and none of our services will be interrupted.

## Ingredients

* 3 x CentOS Atomic hosts (bare-metal or VMs). A reasonable minimum would be:
* 1 x vCPU
* 1GB repo_name
* 10GB HDD
* Hosts must be within the same subnet, and connected on a low-latency link (i.e., no WAN links)

## Preparation

### Release the swarm!

Now, to launch my swarm:

```docker swarm init```

Yeah, that was it. Now I have a 1-node swarm.

```
[root@ds1 ~]# docker swarm init
Swarm initialized: current node (b54vls3wf8xztwfz79nlkivt8) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-2orjbzjzjvm1bbo736xxmxzwaf4rffxwi0tu3zopal4xk4mja0-bsud7xnvhv4cicwi7l6c9s6l0 \
    202.170.164.47:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

[root@ds1 ~]#
```

Run ```docker node ls``` to confirm that I have a 1-node swarm:

```
[root@ds1 ~]# docker node ls
ID                           HOSTNAME                STATUS  AVAILABILITY  MANAGER STATUS
b54vls3wf8xztwfz79nlkivt8 *  ds1.funkypenguin.co.nz  Ready   Active        Leader
[root@ds1 ~]#
```

Note that when I ran ```docker swarm init``` above, the CLI output gave me a command to run to join further nodes to my swarm. This would join the nodes as __workers__ (as opposed to __managers__). Workers can easily be promoted to managers (and demoted again), but since we know that we want our other two nodes to be managers too, it's simpler just to add them to the swarm as managers immediately.

On the first swarm node, generate the necessary token to join another manager by running ```docker swarm join-token manager```:

```
[root@ds1 ~]# docker swarm join-token manager
To add a manager to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-2orjbzjzjvm1bbo736xxmxzwaf4rffxwi0tu3zopal4xk4mja0-cfm24bq2zvfkcwujwlp5zqxta \
    202.170.164.47:2377

[root@ds1 ~]#
```

Run the command provided on your second node to join it to the swarm as a manager. After adding the second node, the output of ```docker node ls``` (on either host) should reflect two nodes:


````
[root@ds2 davidy]# docker node ls
ID                           HOSTNAME                STATUS  AVAILABILITY  MANAGER STATUS
b54vls3wf8xztwfz79nlkivt8    ds1.funkypenguin.co.nz  Ready   Active        Leader
xmw49jt5a1j87a6ihul76gbgy *  ds2.funkypenguin.co.nz  Ready   Active        Reachable
[root@ds2 davidy]#
````

Repeat the process to add your third node.

Finally, ```docker node ls``` should reflect that you have 3 reachable manager nodes, one of whom is the "Leader":

```
[root@ds3 ~]# docker node ls
ID                           HOSTNAME                      STATUS  AVAILABILITY  MANAGER STATUS
36b4twca7i3hkb7qr77i0pr9i    ds1.example.com  Ready   Active        Reachable
l14rfzazbmibh1p9wcoivkv1s *  ds3.example.com  Ready   Active        Reachable
tfsgxmu7q23nuo51wwa4ycpsj    ds2.example.com  Ready   Active        Leader
[root@ds3 ~]#
```

### Create registry mirror

Although we now have shared storage for our persistent container data, our docker nodes don't share any other docker data, such as container images. This results in an inefficiency - every node which participates in the swarm will, at some point, need the docker image for every container deployed in the swarm.

When dealing with large container (looking at you, GitLab!), this can result in several gigabytes of wasted bandwidth per-node, and long delays when restarting containers on an alternate node. (_It also wastes disk space on each node, but we'll get to that in the next section_)

The solution is to run an official Docker registry container as a ["pull-through" cache, or "registry mirror"](https://docs.docker.com/registry/recipes/mirror/). By using our persistent storage for the registry cache, we can ensure we have a single copy of all the containers we've pulled at least once. After the first pull, any subsequent pulls from our nodes will use the cached version from our registry mirror. As a result, services are available more quickly when restarting container nodes, and we can be more aggressive about cleaning up unused containers on our nodes (more later)

The registry mirror runs as a swarm stack, using a simple docker-compose.yml. Customize __your mirror FQDN__ below, so that Traefik will generate the appropriate LetsEncrypt certificates for it, and make it available via HTTPS.

```
version: "3"

services:

  registry-mirror:
    image: registry:2
    networks:
      - traefik
    deploy:
      labels:
        - traefik.frontend.rule=Host:<your mirror FQDN>
        - traefik.docker.network=traefik
        - traefik.port=5000
    ports:
      - 5000:5000
    volumes:
      - /var/data/registry/registry-mirror-data:/var/lib/registry
      - /var/data/registry/registry-mirror-config.yml:/etc/docker/registry/config.yml

networks:
  traefik:
    external: true
```

!!! note "Unencrypted registry"
    We create this registry without consideration for SSL, which will fail if we attempt to use the registry directly. However, we're going to use the HTTPS-proxied version via Traefik, leveraging Traefik to manage the LetsEncrypt certificates required.


Create registry/registry-mirror-config.yml as follows:
```
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

### Enable registry mirror and experimental features

To tell docker to use the registry mirror, and in order to be able to watch the logs of any service from any manager node (_an experimental feature in the current Atomic docker build_), edit **/etc/docker-latest/daemon.json** on each node, and change from:

```
{
    "log-driver": "journald",
    "signature-verification": false
}
```

To:

```
{
    "log-driver": "journald",
    "signature-verification": false,
    "experimental": true,
    "registry-mirrors": ["https://<your registry mirror FQDN>"]
}
```

!!! tip ""
    Note the extra comma required after "false" above

### Setup automated cleanup

This needs to be a docker-compose.yml file, excluding trusted images (like glusterfs, traefik, etc)
```
docker run -d  \
-v /var/run/docker.sock:/var/run/docker.sock:rw \
-v /var/lib/docker:/var/lib/docker:rw  \
meltwater/docker-cleanup:latest
```

### Tweaks

Add some handy bash auto-completion for docker. Without this, you'll get annoyed that you can't autocomplete ```docker stack deploy <blah> -c <blah.yml>``` commands.

```
cd /etc/bash_completion.d/
curl -O https://raw.githubusercontent.com/docker/cli/b75596e1e4d5295ac69b9934d1bd8aff691a0de8/contrib/completion/bash/docker
```

Install some useful bash aliases on each host
```
cd ~
curl -O https://raw.githubusercontent.com/funkypenguin/geek-cookbook/master/examples/scripts/gcb-aliases.sh
echo 'source ~/gcb-aliases.sh' >> ~/.bash_profile
```
