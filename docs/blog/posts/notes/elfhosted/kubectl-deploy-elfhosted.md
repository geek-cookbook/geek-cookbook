---
date: 2023-06-08
categories:
  - note
tags:
  - elfhosted
title: Introducing the ElfHosted experiment
description: Every journey has a beginning. This is the beginning of the ElfHosted journey
---

# Introduction to ElfHosted

I've consulted on the building and operation of an "appbox" platform over the past 2 year, and my client/partner has made the difficult decision to shut the platform down, partly due to increased datacenter power costs, and capital constraints.

So I've got two year's worth of hard-earned lessons and ideas re how to build a GitOps-powered app hosting platform, and a generous and loyal userbase - I don't want to lose either, and I've enjoyed the process of building out the platform, so I thought I'd document the process by setting up ***another** platform, on a smaller scale (*but able to accommodate growth*).

<!-- more -->

--8<-- "what-is-elfhosted.md"

## The Big Picture

### Infrastructure

We'll use Kubernetes. Obviously. :grinning:

But where to get the infrastructure? The appbox hardware was all owned, which was big capital outlay, and while it was fun to drive a big, grunty compute and ceph cluster with redundant 40Gbps network (*for the Ceph nodes*), 10Gbps local and internet connectivity, the power / physical management of the infrascture turned out to be our undoing.

My first thought was to pursue managed Kubernetes clusters, but I was quickly priced out. Next I considered bare-metal managed Kubernetes providers (*servers.com, for example*), but couldn't find something appropriately customizable, resilent, and affordable.

I was directed towards Hetzner's [Server Auction](https://www.hetzner.com/sb), and I found my groove... Hetzner sell older servers at a discount, and based on RAM/CPU, they're simply the most affordable option. The downside is that Hetzner's dedicated server products are very much a "hands-off" arrangement - no magic cloud infrastructure, no elastic block storage, and no managed Kubernetes.

Since managing bare-metal Kubernetes platforms is **literally** my [day job](https://www.funkypenguin.co.nz/work-with-me/), I decided to commit, and ordered a small 64GB 4-core machine as a controller, and a slightly gruntier 12-core, 128GB machine as an initial worker.

=== "Controller"

    ```
    1 x Dedicated Root Server "Server Auction"
        * Intel Core i7-7700
        * 2x SSD M.2 NVMe 512 GB
        * 4x RAM 16384 MB DDR4
        * NIC 1 Gbit Intel I219-LM
        * Location: Germany, FSN1     
    ```

=== "Worker"

    ```
    1 x Dedicated Root Server "Server Auction"
        * Intel Core i9-9900K
        * 2x SSD M.2 NVMe 1 TB
        * 4x RAM 32768 MB DDR4
        * NIC 1 Gbit Intel I219-LM
        * Location: Germany, FSN1
    ```

### Billing System

Our original appbox platform invested in a custom user dashboard, which handled:

1. Account setup and payment
2. App install/uninstall/restart

This ended up being a big investment, and an ongoing source of frustration[^1]. Since we want to iterate ElfHosted quickly, we need an "off-the-shelf" billing system which will "just work". I looked into Shopify, Woocommerce, and several other open-source billing systems.

My philosophy here is that I want as little as possible to do with billing - it's soul-sucking, anti-fun to debug why customer **X** was charged **$Y** instead of **$Z** :rage:!

I settled on the pragmatic approach of using [Woocommerce](https://woocommerce.com/marketplace-sale/) on Wordpress. It's extensible enough for the customization I'll need for service provision, but it's polished / supported enough to handle all the weird edge cases a billing system needs. I paid for the Subscriptions and Bundles addons, after doing some rudimentary testing to confirm that I could get a webhook sent on a user creation / subscription event.

### SSO

One of the killer features of the appbox service was our ability to secure otherwise-insecure applications (*[Gatus](https://github.com/TwiN/gatus), for example*) behind a layer of authentication, in this case driven by Traefik Forward Auth and Auth0. I needed to replace the Auth0 integration with _something_, and in the spirit of quick iteration, I discovered two Wordpress plugins which will allow Wordpress to act as a OIDC authentication server (*sign in with Wordpress*):

* [This one](https://wordpress.org/plugins/miniorange-oauth-20-server/), which is highly polished but the free version is intended to upsell you to an expensive paid version
*[ This other one](https://wordpress.org/plugins/openid-connect-server/), which is very bare-bones, and requires editing Wordpress's config to get it going.

Again, in the interests of expediency, I'm starting with the polished-but-naggy extension!

## Summary

--8<-- "what-is-elfhosted.md"

There are lots more ideas to explore, and problems to solve, but solving billing, infrastructure, and SSO means that the idea "has legs", so let's keep building and testing!

--8<-- "blog-footer.md"

[^1]: Adding products was laborious, and it'd do weird things like cancel subscriptions when an auto-renewal was cancelled, intsead of at the end of the subscription period!