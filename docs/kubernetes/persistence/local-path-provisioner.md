# Local Path Provisioner

[k3s](/kubernetes/cluster/k3s/) installs itself with "Local Path Provisioner", a simple controller whose job it is to create local volumes on each k3s node. If you only have one node, or you just want something simple to start learning with, then `local-path` is ideal, since it requires no further setup.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) deployed with [k3s](/kubernetes/cluster/k3s/)

Here's how you know you've got the StorageClass:

```bash
root@shredder:~# kubectl get sc
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  60m
root@shredder:~#
```

## Preparation

### Basics

A few things you should know:

1. This is not **network storage**. The volume you create will forever be found to the k3s node its pod is executed on. If you later take that node down for maintenance, the pods will not be able to start on other nodes, because they won't find their volumes.
2. The default path for the volumes is `/opt/local-path-provisioner`, although this can be changed by [editing a ConfigMap](https://github.com/rancher/local-path-provisioner/blob/master/README.md#customize-the-configmap). Make sure you have enough disk space! [^1]
3. There's no support for resizing a volume. If you create a volume and later work out that it's too small, you'll have to destroy it and recreate it. (*More sophisticated provisioners like [rook-ceph](/kubernetes/persistence/rook-ceph/) and [topolvm](/kubernetes/persistence/topolvm/) allow for dynamic resizing of volumes*)

### When to use it

* When you don't care much about your storage. This seems backwards, but sometimes you need large amounts of storage for relatively ephemeral reasons, like batch processing, or log aggregation. You may decide the convenience of using Local Path Provisioner for quick, hard-drive-speed storage outweighs the minor hassle of loosing your metrics data if you were to have a node outage.
* When [TopoLVM](/kubernetes/persistence/topolvm/) is not a viable option, and you'd rather use available disk space on your existing, formatted filesystems

### When not to use it

* When you have any form of redundancy requirement on your persisted data.
* When you're not using k3s.
* You may one day want to resize your volumes.

### Summary

In summary, Local Path Provisioner is fine if you have very specifically sized workloads and you don't care about node redundancy.

{% include 'recipe-footer.md' %}

[^1]: [TopoLVM](/kubernetes/persistence/topolvm/) also creates per-node volumes which aren't "portable" between nodes, but because it relies on LVM, it is "capacity-aware", and is able to distribute storage among multiple nodes based on available capacity.
