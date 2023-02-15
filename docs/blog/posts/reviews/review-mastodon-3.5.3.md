---
date: 2022-11-10
categories:
  - Review
tags:
  - mastodon
links:
  - Mastodon Kubernetes recipe: recipes/kubernetes/mastodon.md
  - Mastodon Docker Swarm recipe: recipes/mastodon.md
title: Review / Mastodon v3.5.3 - Open, Federated microblogging platform
description: Mastodon is a twitter-inspired, federated, microblogging community ("social network"), which anybody can partricipate in by joining a public instance, or running their own instance. Here's a review!
image: /images/mastodon.png
upstream_version: v3.5.3
---

# Review of Mastodon - Open, Federated microblogging platform

Mastodon is a twitter-inspired, federated, microblogging community ("social network"), which anybody can partricipate in by joining a public instance, or running their own instance.

<!-- more -->

![Mastodon Screenshot](/images/mastodon.png){ loading=lazy }

| Review details      |                           |
| ----------- | ------------------------------------ |
| :octicons-number-24: Reviewed version       | *[{{ page.meta.upstream_version }}]({{ page.meta.upstream_repo }})* |

Mastodon is a twitter-inspired, federated, microblogging community ("social network"), which anybody can partricipate in by joining a public instance, or running their own instance.

## Background

I've been interested in running a Mastodon instance since I [read about it](https://www.theverge.com/2017/4/4/15177856/mastodon-social-network-twitter-clone) back in 2017. I gave it a try back then, but IIRC Docker support was iffy, and the way federation worked was a bit hit-and-miss (*at least, in my attempts*) I did learn a bit about "[WebFinger](https://docs.joinmastodon.org/spec/webfinger/)" :fingers_crossed: though, which still sounds a bit dirty! :smiling_imp:

![My 2017 Federation-debugging](/images/reviews/mastodon-back-in-2017.png){ loading=lazy }

After abandoning my dreams of hosting an instance, I kept a few accounts on mastodon.social, experimenting with cross-posting from Micro.blog, and using the native RSS feature to provide a manually-created [changelog of new recipes](/blog/).

In 2022, finding myself wanting to up my "social game" without tying myself into Twitter, I started assembling a typically geeky, over-engineered workflow to [cross-post between Mastodon and Twitter](https://crossposter.masto.donte.com.br/), and easily produce RSS feeds.

I decided to take a fresh attempt (*5 years on*) at running [my own instance][community/mastodon], and in the process, I re-introduced myself to elements of the Mastdon experience, which I'll explain below...

## What's notable about Mastodon?

Here are my thoughts:

### Technology

1. There's a [steady cadance of ongoing new releases](https://blog.joinmastodon.org/categories/new-features/), and a dedicated [Patreon](https://www.patreon.com/user?u=619786) and [Sponsor](https://joinmastodon.org/sponsors) supporter base.

2. There are now (*as of April 2022*) [official mobile apps](https://blog.joinmastodon.org/2022/04/official-apps-now-available-for-ios-and-android/) for iOS and Android (*there are also dozens of 3rd-party apps which have appear over the years, but some of these are no longer updated*).

### Culture

Community is hard, [federation can be abused to harass target users and administrators](https://wilwheaton.net/2018/08/the-world-is-a-terrible-place-right-now-and-thats-largely-because-it-is-what-we-make-it/), and community moderation is generally a thankless job.

Social "platforms" are no longer just fun cat pictures, they're a now powerful social tool for effecting change or producing life-destroying harm, and a mature, open-source code-base is an attractive starting point[^1] for those wanting to establish[^2] their own platforms.

Public servers tend to serve [communities](https://joinmastodon.org/communities) of a particular interest, be it art, music, gaming, etc.

## Details

### Docker Install

Mastodon includes a [docker-compose](https://github.com/mastodon/mastodon/blob/main/docker-compose.yml) file for deploying under Docker, but it's not a "fire-and-forget" deal, since there are some manual steps required to migrate (or instantiate) the database, setup users, secrets, etc.

More importantly, since docker-compose will only run containers on a single host, this provides no resilience to failure, and no container orchestration like we're used to with Docker Swarm / Kubernetes.

I've adapted the docker-compose for swarm mode, and written a recipe to [install Mastodon in Docker Swarm][mastodon].

### Kubernetes Install

Mastodon's repo also [includes a helm chart](https://github.com/mastodon/mastodon/tree/main/chart), which makes the process of deploying to Kubernetes **much** simpler than either Docker or Docker Swarm. The chart isn't published on [ArtifactHUB](https://artifacthub.io/packages/search?ts_query_web=mastodon&sort=relevance&page=1) yet (*I hope to fix this with a PR*), which means it's hard to discover.

There are other elements I'd like to improve about the official chart, such as the use of env variables for secrets (*these should ideally be Kubernetes secrets*), but the availability of contructs such as Jobs makes the whole deployment and setup process work.

Here's my an opinionated guite to [installing Mastodon in Kubernetes][k8s/mastodon], which is how I've deployed my [FNKY](https://so.fnky.nz ) instance.

### Admin UI

You could probably browse any public instance to get a feel for the user-facing UI and options, but it's harder to get a feel for the admin backend without performing your own installation. Here's a quick video of the admin options to scratch that itch...

<iframe width="560" height="315" src="https://www.youtube.com/embed/iDBz5HPhQl4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Alternatives

### Twitter

OK, obviously one is a bot-filled :robot: cesspool so scary that Elon Musk doesn't want to buy it, and the other is open-source, self-hosted, federated, and can't be censored, monetized, mined, advertised to, etc.

Here are some other differences...

<figure markdown>
| Feature | :material-twitter: Twitter      | :material-mastodon: Mastodon | Notes
| ----- | ----------- | ------------------------------------ | ----- |
| :octicons-comment-16: A post is.. | a "tweet" | a "toot[^4]/post" :material-thought-bubble-outline: | yes, really! |
| :material-comment-multiple-outline: Sharing a post.. | retweeting | boosting | no, not "retooting"! |
| :material-link: Links count as | 9 chars | 23 chars | Regardless of length of URL |
| :material-counter: Character limit | 280 | 500 | |
| :octicons-video-24: Media | :white_check_mark: | :white_check_mark: | video/audio/images work as you'd expect
| :material-poll: Polls | :white_check_mark: | :white_check_mark: | yes, polls too |
| :material-sunglasses: Privacy | :white_check_mark: | :white_check_mark: | you can hide your toots! |
| :octicons-comment-discussion-16: Threads | :white_check_mark: | :white_check_mark: | like [this](https://so.fnky.nz/web/@funkypenguin/108790252118210551)|
| :material-sticker-emoji: Custom emoji | :x: | :white_check_mark: | like Discord, you can define custom emoji for your community |
| :material-rss: RSS feed | :x: | :white_check_mark: | like [this](https://so.fnky.nz/web/@funkypenguin.rss) |
| :bikini: Content warnings | :x: | :white_check_mark: | hide NSFW content, spoilers, etc |
| :material-police-badge: Moderation | TWTR | per-instance | |

  <figcaption>Mastodon vs Twitter</figcaption>
</figure>

**Conclusion**: Although the primary differentiator is centralized "Big Tech" vs federated open-source, there are some feature advantages (*and some quirks!*) to Mastodon vs Twitter :thumbsup:

## Summary

### TL;DR

If you..

* Just like the tech..
* Want to "*stick it to the man*"..
* Find the concept of an isolated, themed social community attractive...

.. Then join one of the thousands of [available instances](https://joinmastodon.org/communities).

If you additionally:

* Prefer to self-host your own tools..
* Want an instance to share with your community...

.. Then install your own instance in [Docker][mastodon] or [Kubernetes][k8s/mastodon]!

I want to "own" my content[^3], and I want to invest in the [Geek Cookbook community](/community/), so I chose my own instance.

Whichever path you take into the "fediverse", [toot me up](https://so.fnky.nz/@funkypenguin) when you get here!

--8<-- "blog-footer.md"

[^1]: https://blog.joinmastodon.org/2019/07/statement-on-gabs-fork-of-mastodon/
[^2]: https://blog.joinmastodon.org/2021/10/trumps-new-social-media-platform-found-using-mastodon-code/
[^3]: I'll continue to cross-post from Mastodon to Twitter though, for visibility and engagement
[^4]: In a [highly controversial PR](https://github.com/mastodon/mastodon/pull/16080), "toots" were renamed to "posts", although my instance [apparently still uses "Toot!"](https://static.funkypenguin.co.nz/2022/FNKY_2022-08-15_19-50-49.png) by default...
