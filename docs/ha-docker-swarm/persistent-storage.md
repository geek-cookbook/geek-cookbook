# Introduction

While Docker Swarm is great for keeping containers running (and restarting those that fail), it does nothing for persistent storage. This means if you actually want your containers to keep any data persistent across restarts, you need to think about storage.

## Ingredients

!!! summary "Ingredients"
    3 x Virtual Machines (configured earlier), each with:

    * [X] CentOS/Fedora Atomic
    * [X] At least 1GB RAM
    * [X] At least 20GB disk space (_but it'll be tight_)
    * [X] Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)
    * [ ] A second disk, or adequate space on the primary disk for a dedicated data partition

## Preparation

### Create Gluster "bricks"

To build our Gluster volume, we need each of the 3 VMs to provide one "brick". The bricks will be used to create the replicated volume.

On each host, run the following to create your bricks, adjusted for the path to your disk.

```
mkfs.xfs -i size=512 /dev/vdb1
mkdir -p /data/glusterfs/docker-persistent/brick1
echo '/dev/vdb1 /data/glusterfs/docker-persistent/brick1/ xfs defaults 1 2' >> /etc/fstab
mount -a && mount
```

!!! warning "Don't provision all your LVM space"
    Atomic uses LVM to store docker data, and **automatically grows** Docker's volumes as requried. If you commit all your free LVM space to your brick, you'll quickly find (as I did) that docker will start to fail with error messages about insufficient space. If you're going to slice off a portion of your LVM space in /dev/atomicos, make sure you leave enough space for Docker storage, where "enough" depends on how much you plan to pull images, make volumes, etc. I ate through 20GB very quickly doing development, so I ended up provisioning 50GB for atomic alone, with a separate volume for the brick.

### Create glusterfs container

Atomic doesn't include the Gluster server components.  This means we'll have to run glusterd from within a container, with privileged access to the host. Although convoluted, I actually prefer this design since it once again makes the OS "disposable", moving all the config into containers and code.

Run the following on each host:
````
docker run \
   -h glusterfs-server \
   -v /etc/glusterfs:/etc/glusterfs:z \
   -v /var/lib/glusterd:/var/lib/glusterd:z \
   -v /var/log/glusterfs:/var/log/glusterfs:z \
   -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
   -v /data/glusterfs/gv0/brick1:/data/glusterfs/gv0/brick1 \
   -d --privileged=true --net=host \
   --restart=always \
   --name="glusterfs-server" \
   gluster/gluster-centos
````

### Create gluster volume

Now we create a *replicated volume* out of our individual "bricks". On a single node (doesn't matter which), run ```docker exec -it glusterfs-server bash``` to launch a shell inside the container.

Create the gluster volume by running
```gluster volume create gv0 replica 2 server1:/data/glusterfs/gv0/brick1 server2:/data/glusterfs/gv0/brick1 server3:/data/glusterfs/gv0/brick1```

Start the volume by running ```gluster volume start gv0```

The volume is only present on the host you're shelled into though. To add the other hosts to the volume, run ```gluster peer probe <servername>```. Don't probe host from itself.

From one other host, run ```docker exec -it glusterfs-server bash``` to shell into the gluster-server container, and run ```gluster peer probe <original server name>``` to update the name of the host which started the volume.

### Mount gluster volume

On the host (i.e., outside of the container - type ```exit``` if you're still shelled in), create a mountpoint for the data, by running ```mkdir /srv/data```

Add an entry to fstab to ensure the volume is auto-mounted on boot:
