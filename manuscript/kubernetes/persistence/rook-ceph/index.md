---
title: How to use Rook Ceph for Persistent Storage in Kubernetes
description: How to deploy Rook Ceph into your Kubernetes cluster for persistent storage
---
# Persistent storage in Kubernetes with Rook Ceph / CephFS

[Ceph](https://docs.ceph.com/en/quincy/) is a highly-reliable, scalable network storage platform which uses individual disks across participating nodes to provide fault-tolerant storage.

![Ceph Screenshot](/images/ceph.png){ loading=lazy }

[Rook](https://rook.io) provides an operator for Ceph, decomposing the [10-year-old](https://en.wikipedia.org/wiki/Ceph_(software)#Release_history), at-time-arcane, platform into cloud-native components, created declaratively, whose lifecycle is managed by an operator.

The simplest way to think about running rook-ceph is separate the [operator](/kubernetes/persistence/rook-ceph/operator/) (*a generic worker which manages the lifecycle of your cluster*) from your desired [cluster](/kubernetes/persistence/rook-ceph/cluster/) config itself (*spec*).

To this end, I've defined each as a separate component, below:

1. First, install the [operator](/kubernetes/persistence/rook-ceph/operator/)
2. Then, define your [cluster](/kubernetes/persistence/rook-ceph/cluster/)
3. Win!
