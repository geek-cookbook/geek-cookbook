---
title: Balance node usage on Kubernetes with descheduler
description: Use descheduler to balance load on your Kubernetes cluster by "descheduling" pods (to be rescheduled on appropriate nodes)
values_yaml_url: https://github.com/kubernetes-sigs/descheduler/blob/master/charts/descheduler/values.yaml
helm_chart_version: 0.27.x
helm_chart_name: descheduler
helm_chart_repo_name: descheduler
helm_chart_repo_url: https://kubernetes-sigs.github.io/descheduler/
helmrelease_name: descheduler
helmrelease_namespace: descheduler
kustomization_name: descheduler
slug: Descheduler
status: new
upstream: https://sigs.k8s.io/descheduler
links:
- name: GitHub Repo
  uri: https://github.com/kubernetes-sigs/descheduler
---

# Balancing a Kubernetes cluster with descheduler

So you've got multiple nodes in your kubernetes cluster, you throw a bunch of workloads in there, and Kubernetes schedules the workloads onto the nodes, making sensible choices based on load, affinity, etc. 

Note that this scheduling only happens when a pod is created. Once a pod has been scheduled to a node, Kubernetes won't take it **away** from that node. This can result in "sub-optimal" node loading, especially if you're elastically expanding your nodes themselves, or working through rolling updates.

Descheduler is used to rebalance clusters by evicting pods that can potentially be scheduled on better nodes.

![descheduler login](/images/descheduler.png){ loading=lazy }

Here are some reasons you might need to rebalance your cluster:

* Some nodes are under or over utilized.
* The original scheduling decision does not hold true any more, as taints or labels are added to or removed from nodes, pod/node affinity requirements are not satisfied any more.
* Some nodes failed and their pods moved to other nodes.
* New nodes are added to clusters.

Descheduler works by "kicking out" (evicting) certain nodes based on a policy you feed it, depending what you want to achieve. (*You may want to converge as many pods as possible on as few nodes as possible, or more evenly distribute load across a static set of nodes*)

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

## Configure descheduler Helm Chart

The following sections detail suggested changes to the values pasted into `/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml` from the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}). The values are already indented correctly to be copied, pasted into the HelmRelease, and adjusted as necessary.

!!! tip
    Confusingly, the descheduler helm chart defaults to having the bundled redis and postgresql **disabled**, but the [descheduler Kubernetes install](https://godescheduler.io/docs/installation/kubernetes/) docs require that they be enabled. Take care to change the respective `enabled: false` values to `enabled: true` below.

### Set descheduler secret key

## Create your admin user

## Summary

What have we achieved? We've got descheduler running and accessible, we've created a superuser account, and we're ready to flex :muscle: the power of descheduler to deploy an OIDC provider for Kubernetes, or simply secure unprotected UIs with proxy outposts!

!!! summary "Summary"
    Created:

    * [X] descheduler running and ready to "deschedulerate" :lock: !

    Next:

    * [ ] Configure [Kubernetes OIDC authentication](/kubernetes/oidc-authentication/), unlocking production readiness as well as the [Kubernetes Dashboard][k8s/dashboard] and Weave GitOps UIs (*coming soon*)

{% include 'recipe-footer.md' %}

[^1]: Yes, the lower-case thing bothers me too. That's how the official docs do it though, so I'm following suit.