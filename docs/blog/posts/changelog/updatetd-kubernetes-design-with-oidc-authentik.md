---
date: 2023-11-03
categories:
  - CHANGELOG
tags:
  - authentik
  - kubernetes
links:
  - OIDC Authentication: kubernetes/oidc-authentication/index.md
  - K3s OIDC with authentic: kubernetes/oidc-authentication/k3s-authentik.md
  - EKS OIDC with authentic: kubernetes/oidc-authentication/eks-authentik.md
description: Using authentic to provide OIDC auth to a Kubernetes cluster
title: Authentic-ate yourself to your Kubernetes cluster
---

# Authentic-ate yourself to your Kubernetes cluster

Following up on our recent [authentik][k8s/authentik] recipe, I've updated our Kubernetes "Essentials" section to include cluster OIDC authentication, provided by authentik (among others).

<!-- more -->

## Why bother with OIDC cluster authentication?

Consider the following downsides to a single, static, long-lived credential:

1. It can get stolen
2. It can't be shared (*you might want to give your team access to the cluster, or even a limited subset of admin access*)
3. It can't be MFA'd
4. Using it for the Kubernetes Dashboard (*copying and pasting a token into a browser window*) is a huge PITA

For the multi-step process to address all of this, see our [Kubernetes OIDC Authentication guide](/kubernetes/oidc-authentication/)!

--8<-- "common-links.md"