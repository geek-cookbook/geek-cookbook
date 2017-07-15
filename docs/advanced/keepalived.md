# keepalived


## On both hosts

The design for redundant Docker hosts requires a virtual IP for high availability. To enable this, we install the "keepalived" daemon on both hosts:

````yum -y install keepalived````

Below, we'll configure a very basic primary/secondary configuration.

!!! note
    Note that if you have a firewall on your hosts, you need to permit the VRRP traffic, as follows (note that for both INPUT and OUTPUT rule, the destination is 224.0.0.18, a multicast address)

    ````
    # permit keepalived in
    -A INPUT -i eth0 -d 224.0.0.18 -j ACCEPT

    # permit keepalived out
    -A OUTPUT -o eth0 -d 224.0.0.18 -j ACCEPT
    ````

## On the primary

Configure keepalived (note the priority)
````
VIP=<YOUR HA IP>
PASS=<PASSWORD-OF-CHOICE>
cat << EOF > /etc/keepalived/keepalived.conf
vrrp_instance DS {
    state MASTER
    interface eth0
    virtual_router_id 42
    priority 200
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass $PASS
    }
    virtual_ipaddress {
        $VIP
    }
}
EOF
systemctl enable keepalived
systemctl start keepalived
````

## On the secondary

Repeat the same on the secondary (all that changes is the priority - the priority of the secondary must be lower than that of the primary):

````
VIP=<YOUR HA IP>
PASS=<PASSWORD-OF-CHOICE>
cat << EOF > /etc/keepalived/keepalived.conf
vrrp_instance DS {
    state MASTER
    interface eth0
    virtual_router_id 42
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass $PASS
    }
    virtual_ipaddress {
        $VIP
    }
}
EOF
systemctl enable keepalived
systemctl start keepalived
````

Check the state of keepalived on both nodes by running
````systemctl status keepalived````


## Confirm HA function

You should now be able to ping your HA IP address, and you can test the HA function by running ````tail -f /var/log/messages | grep Keepalived```` the secondary node, and turning keepalived off/on on the primary node, by running ````systemctl stop keepalived && sleep 10s && systemctl start keepalived````.

## Docker

On both hosts, run:

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum makecache fast
sudo yum install docker-ce

sudo systemctl start docker
    sudo docker run hello-world




## Setup Swarm

````
[[root@ds1 ~]# docker swarm init
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

mkfs.xfs -i size=512 /dev/vdb1
mkdir -p /srv/glusterfs
echo '/dev/vdb1 /srv/glusterfs/ xfs defaults 1 2' >> /etc/fstab
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



gluster volume create gv0 replica 2 server1:/data/brick1/gv0 server2:/data/brick1/gv0
    gluster volume start gv0

[root@ds2 ~]# gluster peer probe ds1


gluster volume create gv0 replica 2 ds1:/srv/glusterfs/gv0 ds2:/srv/glusterfs/gv0
gluster volume start gv0

[root@ds1 ~]# mkdir /srv/data
[root@ds1 ~]# mount -t glusterfs ds1:/gv0 /srv/data/


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

systemctl disable docker --now
systemctl enable docker-latest --now
sed -i '/DOCKERBINARY/s/^#//g' /etc/sysconfig/docker

atomic host upgrade


docker stack deploy traefik -c traefik.yml

need to deal with selinux though :(, had to set to permissive to get it working

this seemed to work:

https://github.com/dpw/selinux-dockersock


need to add something to rc.local to make glustetr fs mount



added {"experimental":true} to /etc/docker/dameon.json to enable logs of deployed services






echo "modprobe ip_vs" >> /etc/rc.local

for primary / secondary keepalived


docker run -d --name keepalived --restart=always \
  --cap-add=NET_ADMIN --net=host \
  -e KEEPALIVED_UNICAST_PEERS="#PYTHON2BASH:['202.170.164.47', '202.170.164.48']" \
  -e KEEPALIVED_VIRTUAL_IPS=202.170.164.49 \
  -e KEEPALIVED_PRIORITY=100 \
  osixia/keepalived:1.3.5
