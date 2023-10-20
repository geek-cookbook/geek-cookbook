---
title: Prepare for snapshot-controller with snapshot validation webhook
description: Prepare your Kubernetes cluster for CSI snapshot support with snapshot validation webhook
values_yaml_url: https://github.com/piraeusdatastore/helm-charts/blob/main/charts/snapshot-validation-webhook/values.yaml
helm_chart_version: 1.8.x
helm_chart_name: snapshot-validation-webhook
helm_chart_repo_name: piraeus-charts
helm_chart_repo_url: https://piraeus.io/helm-charts/
helmrelease_name: snapshot-validation-webhook
helmrelease_namespace: snapshot-validation-webhook
kustomization_name: snapshot-validation-webhook
slug: Snapshot Validation Webhook
status: new
---

# Prepare for CSI snapshots with the snapshot validation webhook

Before we deploy snapshot-controller to actually **manage** the snapshots we take, we need the validation webhook to make sure it's done "right".

## {{ page.meta.slug }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}
{% include 'kubernetes-flux-check.md' %}

## Summary

What have we achieved? We now have the snapshot validation admission webhook running in the cluster, ready to support [snapshot-controller](/kubernetes/backup/csi-snapshots/snapshot-controller/)!

!!! summary "Summary"
    Created:

    * [X] snapshot-validation-webhook running and ready to validate!

    Next:

    * [ ] Deploy [snapshot-controller]( (/kubernetes/backup/csi-snapshots/snapshot-controller/)) itself

--8<-- "recipe-footer.md"
