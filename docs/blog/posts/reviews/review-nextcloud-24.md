---
date: 2022-08-26
categories:
  - Review
tags:
  - nextcloud
description: An opinionated geek's review of NextCloud 24, how to make 'reliable' sexy!
title: Review / Nextcloud v24 - Sexy on the outside, boring on the inside
upstream_version: v24
image: /images/nextcloud.jpg
links:
  - NextCloud 24 recipe: recipes/nextcloud.md
---

# Nextcloud : Sexy on the outside 🕺, and boring(ly reliable) 🥱 on the inside

The answer (*to "what's sexy on the outside, and boring(ly) reliable on the inside?"*) is..

.. Nextcloud 24, which I reviewed this week, while modernizing the recipe. Read on for details...

<!-- more -->

| Review details      |                           |
| ----------- | ------------------------------------ |
| :octicons-number-24: Reviewed version       | *[{{ page.meta.upstream_version }}]({{ page.meta.upstream_repo }})* |

## Collaboration is boring.. 🥱

Back in 2012, the (*overly-geeky*) company I worked for employed [rdiff-backup](https://rdiff-backup.net/) and some hacky scripts on each staff member's laptop, to maintain a "shared drive". Fortunately, we upgraded from this over-engineered UX disaster to an early version of OwnCloud. OwnCloud then was immature, and would occasionally end up in sync loops/conflicts, "loose" staff's shared files, and and require painful backup/restores, but at least it had a desktop UI.

A few years later, when NextCloud [forked](https://www.zdnet.com/article/owncloud-founder-forks-popular-open-source-cloud/) from OwnCloud, I was tasked with migrating our design, and a big deal was made out of Nextcloud's "personal" vs "shared" syncing folders. I still remember the pain of upgrading from Nextcloud 7 to Nextcloud 8, and dealing with "non-technical" staff who "just want to see their files dammit!"

I also remember how much better Nextcould's activity summary made life - in a glance, we could see all the changes to the various shared folders we used, and syncing issues became rare(er).

Look, there's nothing particularly sexy about a file syncing app. It's not fun to test (by yourself), and it doesn't introduce any ground-breaking features, and once you've deployed it, nobody wants to change / upgrade / tweak it, for fear of impacting people's workflow. It's... boring.

## ... but boring is reliable 🪨

Yes, (*sigh*), boring is good. A collaboration platform that gets out of your way, and "just works", is exactly what you want, boring as it may be. Take it from me, you do not want to be trying to work out which of your 25 remote users has some sort of local issue which is forcing the other 24 users to re-sync gigabytes of data!

It's been a few years since I published a Docker Swarm recipe for Nextcloud, complete with database backups, full-text-search, service discovery and SSL termination. After a [reader pointed out](https://github.com/geek-cookbook/geek-cookbook/issues/228) that the recipe was no longer valid for modern versions of Nextcloud, I refreshed it and made some improvements / simplifications. You can find the latest Docker Swarm recipe for Nextcloud [here][nextcloud].

## Should you try Nextcloud?

TL;DR - It's still boring on the inside. But that's good. The outside though, is increasingly sexy and well-polished.

In the process of running the latest recipe through its paces in CI, I noticed that the UX has come a long way. Under the hood, NextCloud is much the same, with some extra polish, and a few years more ecosystem maturity. Now apps like [Nextcloud Talk](https://nextcloud.com/talk/) (which was beta at the the time) is de-facto, and the integration of 3rd-party apps is well-established.

Nextcloud (*now called "Nextcloud Hub II" for some reason!*) no longer looks like a boring, corporate file collaboration suite. The default page is a "Dashboard", which can be extended with "Widgets" which integrate with the various apps (*of which there are over 100!*) which can be installed from their app store.

Tell me this isn't sexy:

![Nextcloud Screenshot](/images/blog/nextcloud_1.jpg)

And it's not just Nextcloud apps which can create widgets - you can hook up to external services, like this:

![Nextcloud Screenshot](/images/blog/nextcloud_2.jpg)

Here's a quick demo video I made of the admin interface, in case, like me, you like evaluate your tools based on shiny screencasts:

<iframe width="560" height="315" src="https://www.youtube.com/embed/jXDSDHEb1SA" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

So, if collaboration is your thing, or you'd like to try out the 100+ apps now supported by Nextcloud, give it a try. The [recipe][nextcloud] is freshly tested and good-to-go, and if you're a sponsor, you can deploy it automatically using [premix][premix]!

That's it for now - as always, don't be a stranger - hop into Discord and say hi, request a new recipe, or let me know what you thought of Nextcloud!

--8<-- "blog-footer.md"

[^1]: "wife-insurance": When the developer's wife is a primary user of the platform, you can bet he'll be writing quality code! :woman: :material-karate: :man: :bed: :cry:
[^2]: There's a [friendly Discord server](https://discord.com/invite/D8JsnBEuKb) for Immich too!
