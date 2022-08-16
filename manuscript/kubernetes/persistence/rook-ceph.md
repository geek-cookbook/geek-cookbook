---
title: How to use Rook Ceph for Persistent Storage in Kubernetes
description: How to deploy Rook Ceph into your Kubernetes cluster for persistent storage
---

# Persistent storage in Kubernetes with Rook Ceph / CephFS

[Ceph](https://docs.ceph.com/en/quincy/) is a highly-reliable, scalable network storage platform which uses individual disks across participating nodes to provide fault-tolerant storage.

![Ceph Screenshot](/images/ceph.png){ loading=lazy }

[Rook](https://rook.io) provides an operator for Ceph, decomposing the [10-year-old](https://en.wikipedia.org/wiki/Ceph_(software)#Release_history), at-time-arcane, platform into cloud-native components, created declaratively, whose lifecycle is managed by an operator.


## Rook Ceph requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] An [Ingress](/kubernetes/ingress/) to route incoming traffic to services  

    New:

    * [ ] At least 3 nodes with dedicated disks available (*more is better*)

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `/bootstrap/namespaces/namespace-rook-system.yaml`:

```yaml title="/bootstrap/namespaces/namespace-mastodon.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: rook-system
```

### HelmRepository

```yaml title="/bootstrap/helmrepositories/gitepository-rook-release.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: rook-release
  namespace: flux-system
spec:
  interval: 15m
  url: https://charts.rook.io/release
```
