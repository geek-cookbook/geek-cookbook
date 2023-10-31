---
title: Cover your bare (metal) ass with Velero Backups
date: 2023-10-20
tags:
  - velero
categories:
  - note
description: How to use Velero to automatically backup all the stuff you care about in your bare-metal Kubernetes cluster
---
While I've been a little distracted in the last few months assembling [ElfHosted][elfhosted], the platform is now at a level of maturity which no longer requires huge amounts of my time[^1]. I've started "back-porting" learnings from building an open-source, public, multi-tenanted platform back into the cookbook.

--8<-- "what-is-elfhosted.md"

The first of our imported improvements covers how to ensure that you have a trusted backup of the config and state in your cluster. Using [Velero][velero],  [rook-ceph](/kubernetes/persistence/rook-ceph/), and [CSI snapshots](http://localhost:8000/kubernetes/backup/csi-snapshots/), I'm able to snapshot TBs of user data in ElfHosted for the dreaded "*incase-I-screw-it-up*" disaster scenario.

Check out the [Velero][velero] recipe for a detailed guide re applying the same to your cluster!

<!-- more -->

[^1]: For ongoing maintenance, that is. New features still take time!

--8<-- "blog-footer.md"