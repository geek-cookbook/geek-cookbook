# Shared Storage (Ceph)

While Docker Swarm is great for keeping containers running (_and restarting those that fail_), it does nothing for persistent storage. This means if you actually want your containers to keep any data persistent across restarts (_hint: you do!_), you need to provide shared storage to every docker node.

## Design

### Why not GlusterFS?
I originally provided shared storage to my nodes using GlusterFS (see the next recipe for details), but found it difficult to deal with because:

1. GlusterFS requires (n) "bricks", where (n) **has** to be a multiple of your replica count. I.e., if you want 2 copies of everything on shared storage (the minimum to provide redundancy), you **must** have either 2, 4, 6 (etc..) bricks. The HA swarm design calls for minimum of 3 nodes, and so under GlusterFS, my third node can't participate in shared storage at all, unless I start doubling up on bricks-per-node (which then impacts redundancy)
2. GlusterFS turns out to be a giant PITA when you want to restore a failed node. There are at [least 14 steps to follow](https://access.redhat.com/documentation/en-US/Red_Hat_Storage/3/html/Administration_Guide/sect-Replacing_Hosts.html) to replace a brick.
3. I'm pretty sure I messed up the 14-step process above anyway. My replaced brick synced with my "original" brick, but produced errors when querying status via the CLI, and hogged 100% of 1 CPU on the replaced node. Inexperienced with GlusterFS, and unable to diagnose the fault, I switched to a Ceph cluster instead.

### Why Ceph?

1. I'm more familiar with Ceph - I use it in the OpenStack designs I manage
2. Replacing a failed node is **easy**, provided you can put up with the I/O load of rebalancing OSDs after the replacement.
3. CentOS Atomic includes the ceph client in the OS, so while the Ceph OSD/Mon/MSD are running under containers, I can keep an eye (and later, automatically monitor) the status of Ceph from the base OS.

## Ingredients

!!! summary "Ingredients"
    3 x Virtual Machines (configured earlier), each with:

    * [X] CentOS/Fedora Atomic
    * [X] At least 1GB RAM
    * [X] At least 20GB disk space (_but it'll be tight_)
    * [X] Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)
    * [ ] A second disk dedicated to the Ceph OSD

## Preparation

### SELinux

Since our Ceph components will be containerized, we need to ensure the SELinux context on the base OS's ceph files is set correctly:

```
mkdir /var/lib/ceph
chcon -Rt svirt_sandbox_file_t /etc/ceph
chcon -Rt svirt_sandbox_file_t /var/lib/ceph
```
### Setup Monitors

Pick a node, and run the following to stand up the first Ceph mon. Be sure to replace the values for **MON_IP** and **CEPH_PUBLIC_NETWORK** to those specific to your deployment:

```
docker run -d --net=host \
--restart always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-e MON_IP=192.168.31.11 \
-e CEPH_PUBLIC_NETWORK=192.168.31.0/24 \
--name="ceph-mon" \
ceph/daemon mon
```

Now **copy** the contents of /etc/ceph on this first node to the remaining nodes, and **then** run the docker command above (_customizing MON_IP as you go_) on each remaining node. You'll end up with a cluster with 3 monitors (odd number is required for quorum, same as Docker Swarm), and no OSDs (yet)

### Setup Managers

Since Ceph v12 ("Luminous"), some of the non-realtime cluster management responsibilities are delegated to a "manager". Run the following on every node - only one node will be __active__, the others will be in standby:

```
docker run -d --net=host \
--privileged=true \
--pid=host \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
--name="ceph-mgr" \
--restart=always \
ceph/daemon mgr
```

### Setup OSDs

Since we have a OSD-less mon-only cluster currently, prepare for OSD creation by dumping the auth credentials for the OSDs into the appropriate location on the base OS:

```
ceph auth get client.bootstrap-osd -o \
/var/lib/ceph/bootstrap-osd/ceph.keyring
```

On each node, you need a dedicated disk for the OSD. In the example below, I used _/dev/vdd_ (the entire disk, no partitions) for the OSD.

Run the following command on every node:

```
docker run -d --net=host \
--privileged=true \
--pid=host \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-v /dev/:/dev/ \
-e OSD_FORCE_ZAP=1
-e OSD_DEVICE=/dev/vdd \
-e OSD_TYPE=disk \
--name="ceph-osd" \
--restart=always \
ceph/daemon osd_ceph_disk
```

Watch the output by running ```docker logs ceph-osd -f```, and confirm success.

!!! warning "Zapping the device"
    The Ceph OSD container will normally refuse to destroy a partition containing existing data, but above we are instructing ceph to zap (destroy) whatever is on the partition currently. Don't run this against a device you care about, and if you're unsure, omit the "OSD_FORCE_ZAP" variable

### Setup MDSs

In order to mount our ceph pools as filesystems, we'll need Ceph MDS(s). Run the following on each node:

```
docker run -d --net=host \
--name ceph-mds \
--restart always \
-v /var/lib/ceph/:/var/lib/ceph/ \
-v /etc/ceph:/etc/ceph \
-e CEPHFS_CREATE=1 \
-e CEPHFS_DATA_POOL_PG=256 \
-e CEPHFS_METADATA_POOL_PG=256 \
ceph/daemon mds
```
### Apply tweaks

The ceph container seems to configure a pool default of 3 replicas (3 copies of each block are retained), which is one too many for our cluster (we are only protecting against the failure of a single node).

Run the following on any node to reduce the size of the pool to 2 replicas:

```
ceph osd pool set cephfs_data size 2
ceph osd pool set cephfs_metadata size 2
```

Disabled "scrubbing" (which can be IO-intensive, and is unnecessary on a VM) with:

```
ceph osd set noscrub
ceph osd set nodeep-scrub
```


### Create credentials for swarm

In order to mount the ceph volume onto our base host, we need to provide cephx authentication credentials.

On **one** node, create a client for the docker swarm:

```
ceph auth get-or-create client.dockerswarm osd \
'allow rw' mon 'allow r' mds 'allow' > /etc/ceph/keyring.dockerswarm
```

Grab the secret associated with the new user (you'll need this for the /etc/fstab entry below) by running:

```
ceph-authtool /etc/ceph/keyring.dockerswarm -p -n client.dockerswarm
```

### Mount MDS volume

On each noie, create a mountpoint for the data, by running ```mkdir /var/data```, add an entry to fstab to ensure the volume is auto-mounted on boot, and ensure the volume is actually _mounted_ if there's a network / boot delay getting access to the gluster volume:

```
mkdir /var/data

MYHOST=`hostname -s`
echo -e "
# Mount cephfs volume \n
$MYHOST:6789:/      /var/data/      ceph      \
name=dockerswarm\
,secret=<YOUR SECRET HERE>\
,noatime,_netdev,context=system_u:object_r:svirt_sandbox_file_t:s0 \
0 2" >> /etc/fstab
mount -a
```
### Install docker-volume plugin

Upstream bug for docker-latest reported at https://bugs.centos.org/view.php?id=13609

And the alpine fault:
https://github.com/gliderlabs/docker-alpine/issues/317


## Serving

After completing the above, you should have:

```
[X] Persistent storage available to every node
[X] Resiliency in the event of the failure of a single node
```

## Chef's Notes

Future enhancements to this recipe include:

1. Rather than pasting a secret key into /etc/fstab (which feels wrong), I'd prefer to be able to set "secretfile" in /etc/fstab (which just points ceph.mount to a file containing the secret), but under the current CentOS Atomic, we're stuck with "secret", per https://bugzilla.redhat.com/show_bug.cgi?id=1030402
2. This recipe was written with Ceph v11 "Jewel".  Ceph have subsequently releaesd v12 "Kraken". I've updated the recipe for the addition of "Manager" daemons, but it should be noted that the [only reader so far](https://discourse.geek-kitchen.funkypenguin.co.nz/u/ggilley) to attempt a Ceph install using CentOS Atomic and Ceph v12 had issues with OSDs, which lead him to [move to Ubuntu 1604](https://discourse.geek-kitchen.funkypenguin.co.nz/t/shared-storage-ceph-funky-penguins-geek-cookbook/47/24?u=funkypenguin) instead.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
