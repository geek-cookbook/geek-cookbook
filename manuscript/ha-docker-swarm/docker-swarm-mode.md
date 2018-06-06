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


```
[root@ds2 davidy]# docker node ls
ID                           HOSTNAME                STATUS  AVAILABILITY  MANAGER STATUS
b54vls3wf8xztwfz79nlkivt8    ds1.funkypenguin.co.nz  Ready   Active        Leader
xmw49jt5a1j87a6ihul76gbgy *  ds2.funkypenguin.co.nz  Ready   Active        Reachable
[root@ds2 davidy]#
```

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

### Setup automated cleanup

Docker swarm doesn't do any cleanup of old images, so as you experiment with various stacks, and as updated containers are released upstream, you'll soon find yourself loosing gigabytes of disk space to old, unused images.

To address this, we'll run the "[meltwater/docker-cleanup](https://github.com/meltwater/docker-cleanup)" container on all of our nodes. The container will clean up unused images after 30 minutes.

First, create docker-cleanup.env (_mine is under /var/data/config/docker-cleanup_), and exclude container images we **know** we want to keep:

```
KEEP_IMAGES=traefik,keepalived,docker-mailserver
DEBUG=1
```

Then create a docker-compose.yml as follows:

```
version: "3"

services:
  docker-cleanup:
    image: meltwater/docker-cleanup:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker:/var/lib/docker
    networks:
      - internal
    deploy:
      mode: global
    env_file: /var/data/config/docker-cleanup/docker-cleanup.env

networks:
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.0.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.

Launch the cleanup stack by running ```docker stack deploy docker-cleanup -c <path-to-docker-compose.yml>```

### Setup automatic updates

If your swarm runs for a long time, you might find yourself running older container images, after newer versions have been released. If you're the sort of geek who wants to live on the edge, configure [shepherd](https://github.com/djmaze/shepherd) to auto-update your container images regularly.

Create /var/data/config/shepherd/shepherd.env as follows:

```
# Don't auto-update Plex or Emby, I might be watching a movie! (Customize this for the containers you _don't_ want to auto-update)
BLACKLIST_SERVICES="plex_plex emby_emby"
# Run every 24 hours. I _really_ don't need new images more frequently than that!
SLEEP_TIME=1440
```

Then create /var/data/config/shepherd/shepherd.yml as follows:

```
version: "3"

services:
  shepherd-app:
    image: mazzolino/shepherd
    env_file : /var/data/config/shepherd/shepherd.env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    labels:
      - "traefik.enable=false"
    deploy:
      placement:
        constraints: [node.role == manager]
```

Launch shepherd by running ```docker stack deploy shepherd -c /var/data/config/shepherd/shepherd.yml```, and then just forget about it, comfortable in the knowledge that every day, Shepherd will check that your images are the latest available, and if not, will destroy and recreate the container on the latest available image.


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

## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
