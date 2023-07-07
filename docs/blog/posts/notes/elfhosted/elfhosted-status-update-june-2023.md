---
date: 2023-07-08
categories:
  - note
tags:
  - elfhosted
title: Elf-Disclosure / June 2023
description: Recent changes, stats, and plans for ElfHosted from June 2023
---

# "Elf-Disclosure" for June 2023

It's been a month since [ElfHosted][elfhosted] was born! :baby:

I've worked way **more** than I expected, and the work has been **harder** than I expected, but I've immensely enjoyed the challenge of building something **fast** and **in public**.

What follows here are our recent changes, the current stats - time/money spent, revenue (haha), and lots of data / graphs re the current state of the platform.

<!-- more -->

--8<-- "what-is-elfhosted.md"

!!! warning "This post may not format nicely via RSS"
    To make the amount of data presented below easier to parse, I've used mkdocs-material content tables to format / display data. This will probably not look good in a feed reader, so if what follows looks like a huge mess, view it in your browser instead!

## What's new/next?

=== ":material-calendar: June 2023"

    Here's what we achieved in June 2023 (*not an exhaustive list, there's only so much space!*):

    * [x] [Prod website][elfhosted] based on (*you guessed it!*) mkdocs-material (*look familiar?*)
    * [x] HA, fault-tolerant K3s Kubernetes cluster (*3 servers, 3 agents, 3 ceph nodes*)
    * [x] Dedicated CI environment for pre-testing infrastructure changes
    * [x] BYO storage / VPN fully self-service when purchasing via the [store][elfhosted/store]
    * [x] All previously supported Seedplicity [apps][elfhosted/apps] available [^5]
    * [x] CLI tool (*[ElfBot][elfhosted/elfbot]*) for self-service app restarts, backups, resets

=== ":dart: July 2023"

    Here's what's on the short-list for prioritization next:

    * [ ] Bring BYOVPN config to Deluge and ruTorrent
    * [ ] Add new apps to support Premiumize
    * [ ] Migrate to prod store, make bundles easier to manage
    * [ ] Regular daily maintenance period for app updates / maintenance
    * [ ] Load test with more users!

## Stats

Here's our stats, updated for June 2023:

=== ":moneybag: Spent"

    :material-target: Focus | :material-calendar: June 2023 
    ---------|----------
    :material-cow: Cluster | $428
    :material-cart: Store | $632 [^1]
    :material-test-tube: CI | $208 
    :material-cloud-cog: Cloud | $30 
    :material-clock: Development | 146h / $21,900 [^2]

=== ":nerd: Tech stats"

    :material-target: Focus | :material-calendar: June 2023 
    ---------|----------
    :fontawesome-regular-circle-user: Users | 14
    :octicons-sign-in-16: Ingress | 24TB
    :octicons-sign-out-16: Egress | 1TB [^4]
    :material-dolphin: Pods | 478

=== ":bar_chart: Summary"

    :material-target: Focus | :material-calendar: June 2023 
    ---------|---------- 
    :material-trending-down: Total invested thus far | $23,200 [^6]
    :material-trending-up: Revenue | $0 

## Resources

=== ":material-cpu-64-bit: CPU"

    Most apps consume almost no CPU while idle - the larger consumers are streamers doing transcoding, and download clients doing download/unpack operations:

    ![CPU stats for June 2023](/images/blog/elf-cpu-stats-june-2023.png)

=== ":material-memory: RAM"

    This graph represents memory usage across the entire cluster. By far the largest consumers of RAM are the storage platforms (longhorn and ceph):

    ![Memory stats for June 2023](/images/blog/elf-memory-stats-june-2023.png)

=== ":material-server-network: Network"

    I'm not sure these stats are accurate, they've likely overly high because pods on the host network (like metallb, ceph, etc) will end up counting **all** traffic on each host, rather than the pod itself. This is an outstanding issue to fix!

    ![Memory stats for June 2023](/images/blog/elf-network-stats-june-2023.png)

=== ":octicons-graph-16: Ingress/Egress"

    These are the traffic stats for egress from Hetzner. They exclude any traffic to/from Hetzner Storageboxes:

    ![Traffic stats for June 2023](/images/blog/elf-traffic-stats-june-2023.png)

=== ":fontawesome-solid-cow: Longhorn"

    Longhorn provides RWX volumes for `/config`, and for some infrastructure components like Prometheus, Chartmuseum, etc.

    ![Longhorn stats for June 2023](/images/blog/elf-longhorn-stats-june-2023.png)

=== ":simple-ceph: Ceph"

    Ceph provides optional storage ("ElfStorage"), typically used for long-term slow storage and seeding:

    ![Ceph stats for June 2023](/images/blog/elf-ceph-stats-june-2023.png)

## Join us!

!!! tip "Want to get involved?"

    Want to get involved? Join us in [Discord][elfhosted/discord] and come and test-in-production!

[^1]: Much of this is yearly fees for Wordpress plugins
[^2]: Yes, that's a **lot**! This is the opportunity cost, over a month, of focusing on ElfHosted rather than billable consulting work!
[^3]: Total spend includes yearly payments for Wordpress plugins, etc
[^4]: Low egress is good, because ingress is always free, but Hetzner charges for egress after 20TB!
[^5]: Except Minio, which we're not bringing back!
[^6]: All moneyz are in US dollarz!

--8<-- "blog-footer.md"