---
title: Support CSI VolumeSnapshots with snapshot-controller
description: Add CSI VolumeSnapshot support with snapshot support
values_yaml_url: https://github.com/piraeusdatastore/helm-charts/blob/main/charts/snapshot-controller/values.yaml
helm_chart_version: 1.8.x
helm_chart_name: snapshot-controller
helm_chart_repo_name: piraeus-charts
helm_chart_repo_url: https://piraeus.io/helm-charts/
helmrelease_name: snapshot-controller
helmrelease_namespace: snapshot-controller
kustomization_name: snapshot-controller
slug: Snapshot Controller
status: new
---

# Add CSI VolumeSnapshot support with snapshot support

Before we deploy snapshot-controller to actually **manage** the snapshots we take, we need the validation webhook to make sure it's done "right".

## {{ page.meta.slug }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] [snapshot-validation-webhook](/kubernetes/backup/csi-snapshots/snapshot-validation-webhook/) deployed

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

#### Configure for rook-ceph

Under the HelmRelease values which you pasted from upstream, you'll note a section for `volumeSnapshotClasses`. By default, this is populated with commented out examples. To configure snapshot-controller to work with rook-ceph, replace these commented values as illustrated below:

```yaml  title="/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml (continued)"
  values:
    # extra content from upstream
    volumeSnapshotClasses:
    - name: csi-rbdplugin-snapclass
      driver: rook-ceph.rbd.csi.ceph.com # driver:namespace:operator
      labels:
        velero.io/csi-volumesnapshot-class: "true"
      parameters:
        # Specify a string that identifies your cluster. Ceph CSI supports any
        # unique string. When Ceph CSI is deployed by Rook use the Rook namespace,
        # for example "rook-ceph".
        clusterID: rook-ceph # namespace:cluster
        csi.storage.k8s.io/snapshotter-secret-name: rook-csi-rbd-provisioner
        csi.storage.k8s.io/snapshotter-secret-namespace: rook-ceph # namespace:cluster
      deletionPolicy: Delete # docs suggest this may need to be set to "Retain" for restoring
```

{% include 'kubernetes-flux-check.md' %}

## Summary

What have we achieved? We've got snapshot-controller running, and ready to manage VolumeSnapshots on behalf of Velero, for handy in-cluster volume backups!

!!! summary "Summary"
    Created:

    * [X] snapshot-controller running and ready to snap :camera: !

    Next:

    * [ ] Configure [Velero](/kubernetes/backup/velero/) with a VolumeSnapshotLocation, so that volume snapshots can be made as part of a BackupSchedule!

{% include 'recipe-footer.md' %}
