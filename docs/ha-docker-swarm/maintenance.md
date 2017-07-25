# Introduction

## Adding a host

## Adding storage

gluster volume add-brick VOLNAME NEW_BRICK

example

# gluster volume add-brick test-volume server4:/exp4
Add Brick successful

# Replacing failed host

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
