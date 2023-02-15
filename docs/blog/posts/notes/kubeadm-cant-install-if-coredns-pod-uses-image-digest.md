---
date: 2023-02-16
categories:
  - note
tags:
  - kubeadm
  - kubernetes
  - connaisseur
title: Kubeadm will fail to install if you've changed the coredns deployment to use digests
description: I debugged why my kubeadm init command was failing with "start version" .. "not supported" in isCoreDNSConfigMapMigrationRequired
---

# Made changes to your CoreDNS deployment / images? You may find kubeadm uncooperative..

Are you trying to join a new control-plane node to a kubeadm-installed cluster, and seeing an error like this?

```bash
start version '8916c89e1538ea3941b58847e448a2c6d940c01b8e716b20423d2d8b189d3972' not supported
unable to get list of changes to the configuration.
k8s.io/kubernetes/cmd/kubeadm/app/phases/addons/dns.isCoreDNSConfigMapMigrationRequired
```

You've changed your CoreDNS deployment, haven't you? You're using a custom image, or an image digest, or you're using an admissionwebhook to mutate pods upon recreation?

Here's what it means, and how to work around it...

<!-- more -->

We use [Connaisseur](https://github.com/sse-secure-systems/connaisseur) to enforce an internal policy upon our clusters - we don't run any images not signed with [cosign](https://github.com/sigstore/cosign).

!!! question "Why not use [sigstore's policy-controller admission controller](https://docs.sigstore.dev/policy-controller/overview/)?"
    For one, I didn't know it existed before writing this! But having read up on it, here's why I believe that connaisseur is a better choice for our cluster:

    #### connaisseur vs sigstore's policy-controller admission controller

    * [x] Connaisseur can apply to all namespaces by default, and individual namespaces can opt-out
    * [x] Connaisseur can "mutate" manifests, replacing tag-based images with their cosign-verified digest
    * [x] Connaisseur can post slack webhooks to update an ops team re a policy violation, whether in "enforce" or "audit" mode 

When `kubeadm init` instantiates a new control-plane node, it tries to determine which version of CoreDNS is running in the cluster, by **directly examining the coredns pods**.

Here's what one of my pods looks like:

```yaml
Image: registry-internal.elpenguino.net/myorg/coredns:v1.8.6@sha256:8916c89e1538ea3941b58847e448a2c6d940c01b8e716b20423d2d8b189d3972
```

kubeadm doesn't seem to be able to detect that the image above is at `v1.8.6`, and instead assumes it to be `8916...` (*the digest*).

The error can't be worked-around by ignoring a pre-flight test, since this particular failure happens "post-flight", and causes the entire install process to fail. The only viable solution currently (*I'll report this upstream, but it may end up being a "this-is-by-design" issue*), is to explicitly prevent connaisseur from meddling with pods in the `kube-system` namespace, by labelling the namespace with `securesystemsengineering.connaisseur/webhook=ignore`.

Aside from the fact that kubeadm could handle this failure more gracefully, I believe that excluding `kube-system` from admissionwebhooks is a smart move anyway, since `kube-system` should really be inviolate, and any unexpected changes **may** interfere with current and future Kubernetes upgrades anyway!

