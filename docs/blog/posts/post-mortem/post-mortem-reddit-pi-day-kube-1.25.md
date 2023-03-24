---
date: 2023-03-24
categories:
  - Post-Mortem
tags:
  - kubernetes
description: How minor changes like Kubernetes labels can cause massive outage, due to complexity
title: How a Kubernetes 1.24 upgrade broke Reddit for > 5h
links:
  - Official Post-Mortem: https://www.reddit.com/r/RedditEng/comments/11xx5o0/you_broke_reddit_the_piday_outage/
image: /images/blog/reddit_availability_slo.png
---

# How a Kubernetes 1.24 upgrade broke Reddit for > 5h

In a [previous role](https://www.funkypenguin.co.nz/about/) as a senior infrastructure architect, one of my responsibilities was to review and approve post-incident reports, and I've come to appreciate how valuable they can be to improve future reliability.

Nothing motivates positive change like the pain of an unplanned outage, which, when you dig deep enough, could have been entirely avoided had you made different choices in the past.

To keep myself sharp in this role, I would pick public post-mortems[^1], and attempt to analyze them for learnings and ideas that my team could use, without having to make the same mistakes first. I [published some of these reviews on my blog](https://www.funkypenguin.co.nz/blog/spacecraft-and-it-systems-fail-for-the-same-reasons/), but since I've transitioned to consulting and away from SRE-focused roles, I've not kept up with my reading.

This week I read [You Broke Reddit: The Pi-Day Outage](https://www.reddit.com/r/RedditEng/comments/11xx5o0/you_broke_reddit_the_piday_outage/), and decided to revive my old habit of reviewing and commenting on nice, juicy outage reports.

Let's get into it...

<!-- more -->

> It’s funny in an ironic sort of way. As a team, we had just finished up an internal postmortem for a previous Kubernetes upgrade that had gone poorly; but only mildly, and for an entirely resolved cause. So we were kicking off another upgrade of the same cluster.

Every horror movie begins with a harmless and funny situation...

> Upgrades are tested against a dedicated set of clusters, then released to the production environments, working from lowest criticality to highest.

The better you can match your test environment to your production enviroment, the more bugs you'll catch before they sneak through to prod. This requires an investment, however, in resourcing and maintaining your test environments!

> All at once the site came to a screeching halt. We opened an incident immediately, and brought all hands on deck, trying to figure out what had happened. Hands were on deck and in the call by T+3 minutes.

T+3 minutes is snappy. You'd think because the cluster in question was a "big ticket item", the engineers may have been wary of things going wrong, and were waiting anxiously in the wings...

> But, dear Redditor… Kubernetes has no supported downgrade procedure. Because a number of schema and data migrations are performed automatically by Kubernetes during an upgrade, there’s no reverse path defined. Downgrades thus require a restore from a backup and state reload!

Ugh. I'd not really thought about this before, but yes, I wouldn't want to try to go *back* a version!

> We are sufficiently paranoid, so of course our upgrade procedure includes taking a backup as standard. However, this backup procedure, and the restore, were written several years ago. While the restore had been tested repeatedly and extensively in our pilot clusters, it hadn’t been kept fully up to date with changes in our environment, and we’d never had to use it against a production cluster, let alone *this* cluster. This meant, of course, that we were scared of it – We didn’t know precisely how long it would take to perform, but initial estimates were on the order of hours… of *guaranteed* downtime.

I bet in that moment, the thought at the top of everyone's mind was "*Why didn't we test the backup / restore process before we started on this critical, legacy cluster??*"

> At this point, someone spotted that we were getting a lot of timeouts in the API server logs for write operations. But not specifically on the writes themselves. Rather, it was timeouts calling the [admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) on the cluster. Reddit utilizes several different admission controller webhooks. On this cluster in particular, the only admission controller we use that’s generalized to watch all resources is [Open Policy Agent (OPA)](https://www.openpolicyagent.org/).

This has been an early indicator of trouble for us, too. We use [Kyverno](https://kyverno.io/), [TopoLVM](https://github.com/topolvm/topolvm), and various operators which run validating / mutating webhooks, to enforce our polices across the cluster. Although these are all properly HA'd with PDBs and anti-affinity, when there have been significant breakages (*especially the Cilium CNI*), it usually manifests first in the apiserver by the inability to access the webhooks.

Given the far-reaching effectl of a broken admission webhook, and the complexity of the underlying components, we recently went through the exercise of changing most of these webhooks to "fail open", so that if the controller can't be reached **at all** (*not the same as a healthy controller legit denying a request*), kube-apiserver will still be able to effect the change.

> Since it was down anyway, we took this opportunity to delete its webhook configurations.

That's what I normally do to avoid the chicken/egg admissioncontroller problem too! It's not like it's doing its job anyway...

> This procedure had been written against a now end-of-life Kubernetes version, and it pre-dated our switch to CRI-O, which means all of the instructions were written with Docker in mind. This made for several confounding variables where command syntax had changed, arguments were no longer valid, and the procedure had to be rewritten live to accommodate.

This brings back so many bad memories, and makes me want to run backup/restore tests on all my clusters *right now*!

> The route reflectors were set up several years ago by the precursor to the current Compute team. Time passed, and with attrition and growth, everyone who knew they existed moved on to other roles or other companies. Only our largest and most legacy clusters still use them.

[Tale as old as time](https://in.fnky.nz/watch?v=xDUhINW3SPs)..

> The route reflector configuration was thus committed nowhere, leaving us with no record of it, and no breadcrumbs for engineers to follow. One engineer happened to remember that this was a feature we utilized, and did the research during this postmortem process, discovering that this was what actually affected us and how.

:scream_cat:

> The nodeSelector and peerSelector for the route reflectors target the label `node-role.kubernetes.io/master`. In the 1.20 series, Kubernetes [changed its terminology](https://github.com/kubernetes/enhancements/blob/master/keps/sig-cluster-lifecycle/kubeadm/2067-rename-master-label-taint/README.md) from “master” to “control-plane.” And in 1.24, they removed references to “master,” even from running clusters. This is the cause of our outage. Kubernetes node labels.

Gah! I was just dealing with a similar issue this week, in some outdated helm charts. I bet the removal of the `master` label caused more chaos than expected.

## Summary

The post-mortem started with this excellent graph:

![Graph showing Reddit daily availability vs current SLO target](reddit_availability_slo.png){ loading=lazy }

This is a great read, and had me cringing in solidarity at times. The graph above speaks to the excellent work that the Compute team at Reddit has been doing over the past years - I know from personal experience how hard it is to not only maintain but also to upgrade and consolidate an old legacy stack, and I appreciate the detail (*and the classic reddit humor*) which went into this post!

--8<-- "blog-footer.md"

[^1]: There's an amazing collection of post-mortems (including this one) at <https://github.com/danluu/post-mortems>
