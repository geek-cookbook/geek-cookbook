---
title: Deploy Rook Ceph Operator for Persistent Storage in Kubernetes
description: Start your Rook Ceph deployment by installing the operator into your Kubernetes cluster
---

# Persistent storage in Kubernetes with Rook Ceph / CephFS - Operator

[Ceph](https://docs.ceph.com/en/quincy/) is a highly-reliable, scalable network storage platform which uses individual disks across participating nodes to provide fault-tolerant storage.

[Rook](https://rook.io) provides an operator for Ceph, decomposing the [10-year-old](https://en.wikipedia.org/wiki/Ceph_(software)#Release_history), at-time-arcane, platform into cloud-native components, created declaratively, whose lifecycle is managed by an operator.

To start off with, we need to deploy the ceph operator into the cluster, after which, we'll be able to actually deploy our [ceph cluster itself](/kubernetes/persistence/rook-ceph/cluster/).

## Rook Ceph requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `/bootstrap/namespaces/namespace-rook-ceph.yaml`:

```yaml title="/bootstrap/namespaces/namespace-rook-ceph.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: rook-ceph
```

### HelmRepository

We're going to install a helm chart from the Rook Ceph chart repository, so I create the following in my flux repo:

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

### Kustomization

Now that the "global" elements of this deployment (*just the HelmRepository in this case*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/rook-ceph`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-rook-ceph.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: rook-ceph
  namespace: flux-system
spec:
  interval: 30m
  path: ./rook-ceph
  prune: true # remove any elements later removed from the above path
  timeout: 10m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  healthChecks:
    - apiVersion: apiextensions.k8s.io/v1
      kind: CustomResourceDefinition
      name: cephblockpools.ceph.rook.io
```

--8<-- "premix-cta-kubernetes.md"

### ConfigMap

Now we're into the app-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="rook-ceph/configmap-rook-ceph-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: rook-ceph-helm-chart-value-overrides
  namespace: rook-ceph
data:
  values.yaml: |-  # (1)!
    # <upstream values go here>
```

1. Paste in the contents of the upstream `values.yaml` here, intended 4 spaces, and then change the values you need as illustrated below.

Values I change from the default are:

```yaml
pspEnable: false # (1)!
```

1. PSPs are deprecated, and will eventually be removed in Kubernetes 1.25, at which point this will cause breakage.

### HelmRelease

Finally, having set the scene above, we define the HelmRelease which will actually deploy the rook-ceph operator into the cluster. I save this in my flux repo:

```yaml title="/rook-ceph/helmrelease-rook-ceph.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: rook-ceph
  namespace: rook-ceph
spec:
  chart:
    spec:
      chart: rook-ceph
      version: 1.9.x
      sourceRef:
        kind: HelmRepository
        name: rook-release
        namespace: flux-system
  interval: 30m
  timeout: 10m
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: -1 # keep trying to remediate
    crds: CreateReplace # Upgrade CRDs on package update
  releaseName: rook-ceph
  valuesFrom:
  - kind: ConfigMap
    name: rook-ceph-helm-chart-value-overrides
    valuesKey: values.yaml # (1)!
```

1. This is the default, but best to be explicit for clarity

## Install Rook Ceph Operator!

Commit the changes to your flux repository, and either wait for the reconciliation interval, or force  a reconcilliation using `flux reconcile source git flux-system`. You should see the kustomization appear...

```bash
~ ❯ flux get kustomizations rook-ceph
NAME     	READY	MESSAGE                       	REVISION    	SUSPENDED
rook-ceph	True 	Applied revision: main/70da637	main/70da637	False
~ ❯
```

The helmrelease should be reconciled...

```bash
~ ❯ flux get helmreleases -n rook-ceph rook-ceph 
NAME     	READY	MESSAGE                         	REVISION	SUSPENDED
rook-ceph	True 	Release reconciliation succeeded	v1.9.9  	False
~ ❯
```

And you should have happy rook-ceph operator pods:

```bash
~ ❯ k get pods -n rook-ceph -l app=rook-ceph-operator
NAME                                  READY   STATUS    RESTARTS   AGE
rook-ceph-operator-7c94b7446d-nwsss   1/1     Running   0          5m14s
~ ❯
```

## Summary

What have we achieved? We're half-way to getting a ceph cluster, having deployed the operator which will manage the lifecycle of the [ceph cluster](/kubernetes/persistence/rook-ceph/cluster/) we're about to create!

!!! summary "Summary"
    Created:

    * [X] Rook ceph operator running and ready to deploy a cluster!

    Next:

    * [ ] Deploy the ceph [cluster](/kubernetes/persistence/rook-ceph/cluster/) using a CR

{% include 'recipe-footer.md' %}
