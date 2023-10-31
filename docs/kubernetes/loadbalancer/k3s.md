---
title: klipper loadbalancer with k3s
description: klipper - k3s' lightweight loadbalancer
---

# K3s Load Balancing with Klipper

If your cluster is using K3s, and you have only one node, then you could be adequately served by the [built in "klipper" loadbalbancer provided with k3s](https://rancher.com/docs/k3s/latest/en/networking/#service-load-balancer).

If you want more than one node in your cluster[^1] (*either now or in future*), I'd steer you towards [MetalLB](/kubernetes/loadbalancer/metallb/) instead).

## How does it work?

When **not** deployed with `--disable servicelb`, every time you create a service of type `LoadBalancer`, k3s will deploy a daemonset (*a collection of pods which run on every host in the cluster*), listening on that given port on the host. So deploying a LoadBalancer service for nginx on ports 80 and 443, for example, would result in **every** cluster host listening on ports 80 and 443, and sending any incoming traffic to the nginx service.

## Well that's great, isn't it?

Yes, to get you started. But consider the following limitations:

1. This magic can only happen **once** per port. So you can't, for example, run two mysql instances on port 3306.
2. Because **every** host listens on the exposed ports, you can't run anything **else** on the hosts, which listens on those ports
3. Having multiple hosts listening on a given port still doesn't solve the problem of how to reliably direct traffic to all hosts, and how to gracefully fail over if one of the hosts fails.

To tackle these issues, you need some more advanced network configuration, along with [MetalLB](/kubernetes/loadbalancer/metallb/).

{% include 'recipe-footer.md' %}

[^1]: And seriously, if you're building a Kubernetes cluster, of **course** you'll want more than one host!
