---
date: 2023-08-02
categories:
  - note
tags:
  - elfhosted
title: July 2023 "Elf Disclosure" - 0.1% profitable, 99.9% growth remaining!
description: The ElfHosted monthly report detailing changes for July 2023, and summarizing metrics, is now available!
---

# ElfDisclosure for July 2023 : GitOps-based SaaS now Open Source

I've just finished putting together a progress report [ElfHosted][elfhosted] for July 2023. The report details all the changes we went through during the months (*more than I remember!*), and summarizes our various metrics (*CPU, Network, etc.*)

--8<-- "what-is-elfhosted.md"

Of particular note here is that the GitOps and helm chart repos which power a production, HA SaaS, are now [fully open-sourced](https://elfhosted.com/open)!

(Oh, and we generated **actual** revenue during July 2023!)

Here's a high-level summary:

<!-- more -->

!!! warning "This post may not format nicely via RSS"
    To make the amount of data presented below easier to parse, I've used mkdocs-material content tables to format / display data. This will probably not look good in a feed reader, so if what follows looks like a huge mess, view it in your browser instead!

=== ":moneybag: Spent"

    :material-target: Focus | :material-calendar: June 2023 | :material-calendar: July 2023 
    ---------|----------|---------- 
    :material-cow: Cluster | $428 | $428
    :material-cart: Store | $632 | $223
    :material-test-tube: CI | $208 | $200
    :material-cloud-cog: Cloud | $30 | $20 
    :material-clock: Development[^2] | 146h / $21,900 | 124h / $18,600

=== ":nerd: Tech stats"

    :material-target: Focus | :material-calendar: June 2023 | :material-calendar: July 2023 
    ---------|----------|---------- 
    :fontawesome-regular-circle-user: Users | 14 | 48
    :octicons-sign-in-16: Ingress | 24TB | 19.5TB
    :octicons-sign-out-16: Egress | 1TB | 3.3TB
    :material-dolphin: Pods | 478 | 619

=== ":bar_chart: Summary"

    :material-target: Focus | :material-calendar: June 2023 | :material-calendar: June 2023 
    ---------|----------|---------- 
    :material-trending-down: Total invested thus far | $23,200 | $42,669 [^1]
    :material-trending-up: Revenue | $0 | $43 (0.1% of total invested!)

More details and pretty graphs in the [report](https://elfhosted.com/open/july-2023/)!

## Join us!

!!! tip "Want to get involved?"

    Want to get involved? Join us in [Discord][elfhosted/discord] and come and test-in-production!

[^1]: All moneyz are in US dollarz!
[^2]: Yes, that's a **lot**! This is the opportunity cost of focusing on ElfHosted rather than billable consulting work!

--8<-- "blog-footer.md"