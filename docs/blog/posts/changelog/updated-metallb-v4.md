---
date: 2023-01-16
categories:
  - CHANGELOG
tags:
  - metallb
links:
  - MetalLB recipe: /kubernetes/loadbalancer/metallb.md
description: Prior to v0.13, MetalLB was configured using a ConfigMap. This has all changed now, and CRDs are required to perform configuration (which improves syntax checking, abong other things)
---

# Updated MetalLB recipe for CRDs

Prior to v0.13, [MetalLB][metallb] was configured using a ConfigMap. This has all changed now, and CRDs are required to perform configuration (which improves syntax checking, abong other things)

<!-- more -->

[MetalLB](https://metallb.universe.tf/) offers a network [load balancer](/kubernetes/loadbalancer/) implementation which workes on "bare metal" (*as opposed to a cloud provider*).

MetalLB does two jobs:

1. Provides address allocation to services out of a pool of addresses which you define
2. Announces these addresses to devices outside the cluster, either using ARP/NDP (L2) or BGP (L3)

--8<-- "common-links.md"