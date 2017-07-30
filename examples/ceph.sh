sudo chcon -Rt svirt_sandbox_file_t /etc/ceph
sudo chcon -Rt svirt_sandbox_file_t /var/lib/ceph

docker run -d --net=host \
--privileged=true \
--pid=host \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-v /dev/:/dev/ \
-e OSD_DEVICE=/dev/vdd \
-e OSD_TYPE=disk \
--name="ceph-osd" \
--restart=always \
ceph/daemon osd



docker run -d --net=host \
--restart always \
-v /etc/ceph:/etc/ceph \
-v /var/lib/ceph/:/var/lib/ceph/ \
-e MON_IP=192.168.31.11 \
-e CEPH_PUBLIC_NETWORK=192.168.31.0/24 \
--name="ceph-mon" \
ceph/daemon mon

On other nodes

ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring


docker run -d --net=host \
--name ceph-mds \
--restart always \
-v /var/lib/ceph/:/var/lib/ceph/ \
-v /etc/ceph:/etc/ceph \
-e CEPHFS_CREATE=0 \
ceph/daemon mds


ceph auth get-or-create client.dockerswarm osd 'allow rw' mon 'allow r' mds 'allow' > /etc/ceph/keyring.dockerswarm

ceph-authtool /etc/ceph/keyring.dockerswarm -p -n client.dockerswarm

Note that current design seems to provide 3 replicas, which is probably overkill:

[root@ds3 traefik]# ceph osd pool get cephfs_data size
size: 3
[root@ds3 traefik]#


So I set it to 2

[root@ds3 traefik]# ceph osd pool set cephfs_data size 2
set pool 1 size to 2
[root@ds3 traefik]# ceph osd pool get cephfs_data size
size: 2
[root@ds3 traefik]#

Would like to be able to set secretfile in /etc/fstab, but for now it loosk like we're stuch with --secret, per https://bugzilla.redhat.com/show_bug.cgi?id=1030402

Euught. ceph writes are slow (surprise!)

I disabled scrubbing with:

ceph osd set noscrub
ceph osd set nodeep-scrub
