---
date: 2023-11-08
categories:
  - CHANGELOG
tags:
  - kubernetes
links:
  - OAuth2 Proxy: recipes/kubernetes/oauth2-proxy.md
  - Kubernetes Dashboard: recipes/kubernetes/dashboard.md
description: How to add OAuth2 Proxy and Kubernetes Dashboard to your OIDC-enabled cluster for a seamless and secure web UI
title: Added Kubernetes Dashboard and OAuth2 Proxy
image: /images/kubernetes-dashboard.png
---

# Added recipe for Kubernetes Dashboard with OIDC auth

Unless you're a cave-dwelling CLI geek like me, you might prefer a beautiful web-based dashboard to administer your Kubernetes cluster.

![Screenshot of Kubernetes Dashboard]({{ page.meta.image }}){ loading=lazy }

I've recently documented the necessary building blocks to make the dashboard work with your OIDC-enabled cluster, such that a simple browser login will give you authenticated access to the dashboard, with the option to add more users / tiered access, based on your OIDC provider.

Here's all the pieces you need..

<!-- more -->

* [x] An OIDC Provider, like [authentik][k8s/authentik] or [Keycloak][keycloak] (*Kubernetes recipe coming soon*)
* [x] An OIDC-enabled cluster, using [K3s](/kubernetes/cluster/k3s/), [EKS](/kubernetes/cluster/eks/), or (*coming soon*) kubeadm 
* [x] [OAuth2-Proxy][k8s/oauth2proxy] to provide the Kubernetes Dashboard token

And finally, see the [Kubernetes Dashboard tutorial][k8s/dashboard] for more!

--8<-- "common-links.md"
