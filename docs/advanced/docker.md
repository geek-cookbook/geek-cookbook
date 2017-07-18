# Docker Swarm

For truly highly-available services with Docker containers, we need an orchestration system. Docker Swarm (as defined at 1.13) is the simplest way to achieve redundancy, such that a single docker host could be turned off, and none of our services will be interrupted.

## Ingredients

* 2 x CentOS Atomic hosts (bare-metal or VMs). A reasonable minimum would be:
* 1 x vCPU
* 1GB repo_name
* 10GB HDD
* Hosts must be within the same subnet, and connected on a low-latency link (i.e., no WAN links)

## Preparation

### Install CentOS Atomic hosts

I decided to use CentOS Atomic rather than full-blown CentOS7, for the following reasons:

1. I want less responsibility for maintaining the system, including ensuring regular software updates and reboots. Atomic's idempotent nature means the OS is largely real-only, and updates/rollbacks are "atomic" (haha) procedures, which can be easily rolled back if required.
2. For someone used to administrating servers individually, Atomic is a PITA. You have to employ [tricky](http://blog.oddbit.com/2015/03/10/booting-cloud-images-with-libvirt/) [tricks](https://spinningmatt.wordpress.com/2014/01/08/a-recipe-for-starting-cloud-images-with-virt-install/) to get it to install in a non-cloud environment. It's not designed for tweaking or customizing beyond what cloud-config is capable of. For my purposes, this is good, because it forces me to change my thinking - to consider every daemon as a container, and every config as code, to be checked in and version-controlled. Atomic forces this thinking on you.
3. I want the design to be as "portable" as possible. While I run it on VPSs now, I may want to migrate it to a "cloud" provider in the future, and I'll want the most portable, reproducible design.

```
systemctl disable docker --now
systemctl enable docker-latest --now
sed -i '/DOCKERBINARY/s/^#//g' /etc/sysconfig/docker

atomic host upgrade
```

## Setup Swarm

Setting up swarm really is straightforward. You need to ensure that the nodes can talk to each other.

In my case, my nodes are on a shared subnet with other VPSs, so I wanted to ensure that they were not exposed more than necessary. If I were doing this within a cloud infrastructure which provided separation of instances, I wouldn't need to be so specific:

```
# Permit Docker Swarm from other nodes/managers
-A INPUT -s 202.170.164.47 -p tcp --dport 2376 -j ACCEPT
-A INPUT -s 202.170.164.47 -p tcp --dport 2377 -j ACCEPT
-A INPUT -s 202.170.164.47 -p tcp --dport 7946 -j ACCEPT
-A INPUT -s 202.170.164.47 -p udp --dport 7946 -j ACCEPT
-A INPUT -s 202.170.164.47 -p udp --dport 4789 -j ACCEPT
```

````

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

Right, so I a 1-node swarm:

```
[root@ds1 ~]# docker node ls
ID                           HOSTNAME                STATUS  AVAILABILITY  MANAGER STATUS
b54vls3wf8xztwfz79nlkivt8 *  ds1.funkypenguin.co.nz  Ready   Active        Leader
[root@ds1 ~]#
```

If I followed the "join" command above, I'd end up with a worker node. In my case, I actually want another manager, so that I have full HA, so I followed the instruction and ran ```docker swarm join-token manager``` instead.:

```
[root@ds1 ~]# docker swarm join-token manager
To add a manager to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-2orjbzjzjvm1bbo736xxmxzwaf4rffxwi0tu3zopal4xk4mja0-cfm24bq2zvfkcwujwlp5zqxta \
    202.170.164.47:2377

[root@ds1 ~]#
```

I run the command:

````
[root@ds2 davidy]# docker node ls
ID                           HOSTNAME                STATUS  AVAILABILITY  MANAGER STATUS
b54vls3wf8xztwfz79nlkivt8    ds1.funkypenguin.co.nz  Ready   Active        Leader
xmw49jt5a1j87a6ihul76gbgy *  ds2.funkypenguin.co.nz  Ready   Active        Reachable
[root@ds2 davidy]#
````


Swarm initialized: current node (25fw5695wkqxm8mtwqnktwykr) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-54al7nosz9jzj41a8d6kjhz2yez7zxgbdw362f821j81svqofo-e9rw3a8pi53jhlghuyscm52bn \
    202.170.161.87:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

[root@ds1 ~]# docker swarm join-token manager
To add a manager to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-54al7nosz9jzj41a8d6kjhz2yez7zxgbdw362f821j81svqofo-1sjspmbyxqvica5gdb5p4n7mh \
    202.170.161.87:2377

[root@ds1 ~]#
````

Added the second host to the swarm, then promoted it.

````
[root@ds2 ~]#     docker swarm join \
>     --token SWMTKN-1-54al7nosz9jzj41a8d6kjhz2yez7zxgbdw362f821j81svqofo-1sjspmbyxqvica5gdb5p4n7mh \
>     202.170.161.87:2377
This node joined a swarm as a manager.
[root@ds2 ~]#
````

lvcreate -l 100%FREE -n gfs /dev/atomicos
mkfs.xfs -i size=512 /dev/atomicos/gfs
mkdir -p /srv/glusterfs
echo '//dev/atomicos/gfs /srv/glusterfs/ xfs defaults 1 2' >> /etc/fstab
mount -a && mount

````
docker run \
   -h glusterfs-server \
   -v /etc/glusterfs:/etc/glusterfs:z \
   -v /var/lib/glusterd:/var/lib/glusterd:z \
   -v /var/log/glusterfs:/var/log/glusterfs:z \
   -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
   -v /var/srv/glusterfs:/var/srv/glusterfs \
   -d --privileged=true --net=host \
   --restart=always \
   --name="glusterfs-server" \
   gluster/gluster-centos
````



now exec into the container, and "probe" its peer, to establish the gluster cluster

```
[root@ds1 ~]# docker exec -it glusterfs-server bash
[root@glusterfs-server /]#
```

```
[root@glusterfs-server /]# gluster peer probe ds2
peer probe: success.
[root@glusterfs-server /]# gluster peer status
Number of Peers: 1

Hostname: ds2
Uuid: 9fbc1985-4e8d-4380-9c10-3c699ebcb10c
State: Peer in Cluster (Connected)
[root@glusterfs-server /]# exit
exit
[root@ds1 ~]#
```

Run ```gluster volume create gv0 replica 2 ds1:/var/srv/glusterfs/gv0 ds2:/var/srv/glusterfs/gv0``` as below to create the cluster:
```
[root@glusterfs-server /]# gluster volume create gv0 replica 2 ds1:/var/srv/glusterfs/gv0 ds2:/var/srv/glusterfs/gv0
volume create: gv0: success: please start the volume to access data
[root@glusterfs-server /]#
```

Run ```gluster volume start gv0``` to start it:

```
[root@glusterfs-server /]# gluster volume start gv0
volume start: gv0: success
[root@glusterfs-server /]#
```

Exit out of the container:
```
[root@glusterfs-server /]# exit
exit
[root@ds1 ~]#
```

Create your mountpoint on the host, and mount the gluster volume:

```
mkdir /srv/data
HOSTNAME=`hostname -s`
echo "$HOSTNAME:/gv0                /srv/data       glusterfs       defaults,_netdev  0  0" >> /etc/fstab
mount -a && mount
```

  mount -t glusterfs ds1:/gv0 /srv/data/


on secondary
mkdir /srv/data
mount -t glusterfs ds2:/gv0 /srv/data/


/dev/VG-vda3/gv0        /srv/glusterfs  xfs             defaults 1 2
ds2:/gv0                /srv/data       glusterfs       defaults,_netdev  0  0


install docker-compose:

````
curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
````


### Atomic hosts




docker stack deploy traefik -c traefik.yml

need to deal with selinux though :(, had to set to permissive to get it working

this seemed to work:

https://github.com/dpw/selinux-dockersock

````
mkdir ~/dockersock
cd ~/dockersock
curl -O https://raw.githubusercontent.com/dpw/selinux-dockersock/master/Makefile
curl -O https://raw.githubusercontent.com/dpw/selinux-dockersock/master/dockersock.te
make && semodule -i dockersock.pp
````

however... glusterfs still doesn't support selinux, so until that's sorted, you have te disable selinux anyway with "setenforce 0", in order for _ANY_ containers to write to the glusterfs fuse partition.

need to add something to rc.local to make glustetr fs mount

__ maybe __this works:
setsebool -P virt_sandbox_use_fusefs on




added {"experimental":true} to /etc/docker-latest/daemon.json to enable logs of deployed services

I.e changed this:

```
Usage:	docker stack COMMAND
{
    "log-driver": "journald",
    "signature-verification": false
}
```

To this:

```
{
    "log-driver": "journald",
    "signature-verification": false,
    "experimental": true
}```

!!! note the comma after "false" above
