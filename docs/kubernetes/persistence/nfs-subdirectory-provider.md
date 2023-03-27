---
description: How to install the NSF-Subdir provider
recipe: NFS-Subdirectory Provider
title: Use an NFS server for your storage in Kubernetes
image: /images/<recipe name>.png
---

# {{ page.meta.recipe }} on Kubernetes 

This storage provider allows you to use an NFS server like a native K8s storage provider, allowing you to use non-duplicated mass storage for things like media or other large files

## {{ page.meta.recipe }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

    New:

    * [ ] An already existing NFS server

## Preparation

!!! warning

This recpie assumes you have an NFS server ready to go with a username and a password. Setting this up is outside the current scope of this recipe. This provider is also not to be used for persisting SQLite databases, as storing them on NFS will cause the database to corrupt.

### HelmRepository

We're going to install a helm chart from the NFS Subdirectory External Provisioner chart repository, so I create the following in my flux repo:


```yaml title="/bootstrap/helmrepositories/nfs-subdir-provider.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: nfs-subdir
  namespace: flux-system
spec:
  interval: 15m
  url: https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
```

Note that I have shortened the name to nfs-subdir, a theme you will find running throughout.[^1]

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `/bootstrap/namespaces/namespace-nfs-subdir.yaml`:

```yaml title="/bootstrap/namespaces/namespace-nfs-subdir.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: nfs-subdir
```

### Kustomization

Now that the "global" elements of this deployment have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/nfs-subdir`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-nfs-subdir.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: nfs-subdir
  namespace: flux-system
spec:
  interval: 15m
  path: nfs-subdir
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  validation: server
```
!!! warning

Needs some sort of health check!

### ConfigMap

Now we're into the nfs-subdir-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="nfs-subdir/configmap-nfs-subdir-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: nfs-subdir-helm-chart-value-overrides
  namespace: nfs-subdir
data:
  values.yaml: |-  # (1)!
    # <upstream values go here>
```

1. Paste in the contents of the upstream `values.yaml` here, intended 4 spaces, and then change the values you need as illustrated below.

Values you will want to change from the default are:

```yaml
    nfs:
      server: #insert server IP or DNS name here
      path: #Insert mount path here
      mountOptions: #Set things like your user or specific versions here
```


### HelmRelease

Finally, having set the scene above, we define the HelmRelease which will actually deploy the provider into the cluster. I save this in my flux repo:

```yaml title="/nfs-subdir/helmrelease-nfs-subdir.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: nfs-subdir
  namespace: nfs-subdir 
spec:
  chart:
    spec:
      chart: nfs-subdir-external-provisioner
      version: 4.X.X
      sourceRef:
        kind: HelmRepository
        name: nfs-subdir
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: nfs-subdir-external-provisioner
  valuesFrom:
  - kind: ConfigMap
    name: nfs-subdir-helm-chart-value-overrides
    valuesKey: values.yaml # This is the default, but best to be explicit for clarity
```

## :octicons-video-16: Install the provider.

Commit the changes to your flux repository, and either wait for the reconciliation interval, or force  a reconcilliation using `flux reconcile source git flux-system`. You should see the kustomization appear...

```bash
~ ❯ flux get kustomizations | grep nfs-subdir
nfs-subdir                      main@sha1:f1b8c5ad      False           True    Applied revision: main@sha1:f1b8c5ad
~ ❯
```

The helmrelease should be reconciled...

```bash
~ ❯  $ flux get helmreleases -n nfs-subdir
NAME     	REVISION	SUSPENDED	READY	MESSAGE
nfs-subdir      4.0.18          False           True    Release reconciliation succeeded
~ ❯
```

And you should have a happy NFS-Subdirectory pod:

```bash
~ ❯ kubectl get pods -n nfs-subdir 
NAME                                              READY   STATUS    RESTARTS         AGE
nfs-subdir-external-provisioner-9cf9d78b5-6zd7r   1/1     Running   22 (4d11h ago)   105d
~ ❯
```

You can now use this new provider to use an extrernal NFS server for storage. Why would this be useful? Things that you don't want to be replicated, for example, media or large data such as game servers! Of course, this does add a singe point of failure, but a lot less expensive than replicaing data out to many nodes.

## Summary

What have we achieved? We have a storage provider that can use an NFS server as it's storage backend, useful for large files, such as media for the autopirate recipe!

!!! summary "Summary"
    Created:

    * [X] We have a new storage provider

--8<-- "recipe-footer.md"

[^1]: The reason I shortened it is so I didn't have to type nfs-subdirectory-provider each time. If you want that sort of pain in your life, feel free to change it!
