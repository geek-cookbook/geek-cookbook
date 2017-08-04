# Introduction

## Adding a host

## Adding storage

gluster volume add-brick VOLNAME NEW_BRICK

example

# gluster volume add-brick test-volume server4:/exp4
Add Brick successful

# Replacing failed host

Followed https://access.redhat.com/documentation/en-US/Red_Hat_Storage/3/html/Administration_Guide/sect-Replacing_Hosts.html


[root@glusterfs-server /]# gluster peer status
Number of Peers: 1

Hostname: ds1
Uuid: db9c80da-11e4-461d-8ea5-66dd12ca897c
State: Peer in Cluster (Disconnected)
[root@glusterfs-server /]#

Grab UUID above

edit /var/lib/glusterd/glusterd.info
change:
UUID=aee45c2c-aa19-4d29-bc94-4833f2b22863
to
UUID=db9c80da-11e4-461d-8ea5-66dd12ca897c

My peer's id (ds2):
[root@glusterfs-server /]# gluster system:: uuid get
UUID: 38ca4e8b-8ef5-4165-9f41-5c8b3f0103cc
[root@glusterfs-server /]#

vi /var/lib/glusterd/peers/38ca4e8b-8ef5-4165-9f41-5c8b3f0103cc

UUID=38ca4e8b-8ef5-4165-9f41-5c8b3f0103cc
state=3
hostname=ds3



Got volume info


[root@glusterfs-server /]# gluster volume info

Volume Name: gv0
Type: Replicate
Volume ID: 84e1169c-41dc-467a-9ae1-a474efaf789f
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: ds1:/var/no-direct-write-here/brick1/gv0
Brick2: ds3:/var/no-direct-write-here/brick1/gv0
Options Reconfigured:
nfs.disable: on
transport.address-family: inet
[root@glusterfs-server /]#



----
[root@glusterfs-server /]# getfattr -d -m. -ehex /var/no-direct-write-here/brick1/gv0/
getfattr: Removing leading '/' from absolute path names
# file: var/no-direct-write-here/brick1/gv0/
security.selinux=0x73797374656d5f753a6f626a6563745f723a756e6c6162656c65645f743a733000
trusted.gfid=0x00000000000000000000000000000001
trusted.glusterfs.dht=0x000000010000000000000000ffffffff
trusted.glusterfs.volume-id=0x84e1169c41dc467a9ae1a474efaf789f

[root@glusterfs-server /]#



setfattr -n trusted.glusterfs.volume-id -v 0x84e1169c41dc467a9ae1a474efaf789f /var/no-direct-write-here/brick1/gv0
