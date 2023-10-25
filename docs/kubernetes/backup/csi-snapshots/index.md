---
title: Creating CSI snapshots on bare-metal Kubernetes
description: How to use snapshot controller on your bare-metal Kubernetes to create volume snapshots
---
# Creating CSI snapshots

Available since Kubernetes 1.20, Volume Snapshots work with your storage provider to create snapshots of your volumes. If you're using a managed Kubernetes provider, you probably already have snapshot support, but if you're a bare-metal cave-monkey :monkey: using snapshot-capable storage provider (*like [Rook Ceph](/kubernetes/persistence/rook-ceph/)*), you need to jump through some hoops to enable support.

K8s-sig-storage publishes [external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter), which talks to your CSI providers, and manages the creation / update / deletion of snapshots.

!!! question "Why do I care about snapshots?"
    If you've got persistent data you care about in your cluster, you probably care enough to [back it up](/kubernetes/backup/). Although you don't **need** snapshot support for backups, having a local snapshot managed by your backup tool can rapidly reduce the time taken to restore from a failed upgrade, accidental deletion, etc.

There are two components required in order to bring snapshot-taking powerz to your bare-metal cluster, detailed below:

1. First, install the [snapshot validation webhook](/kubernetes/csi-snapshots/snapshot-validation-webhook.md/)
2. Then, install the [snapshot controller](/kubernetes/csi-snapshots/snapshot-controller.md)
3. Install a snapshot-supporting :camera: [backup tool](/kubernetes/backup/) 
