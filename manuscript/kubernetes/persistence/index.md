# Persistence

So we've gone as far as we can with our cluster, without any form of persistence. As soon as we want to retain data, be it a database, metrics history, or objects, we need one or more ways to persist data within the cluster.

Here are some popular options, ranked in difficulty/complexity, in vaguely ascending order:

* [Local Path Provisioner](/kubernetes/persistence/local-path-provisioner/) (on k3s)
* [TopoLVM](/kubernetes/persistence/topolvm/)
* OpenEBS (coming soon)
* Rook Ceph (coming soon)
* Longhorn (coming soon)
