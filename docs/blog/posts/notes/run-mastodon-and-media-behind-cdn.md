---
date: 2023-02-09
categories:
  - note
tags:
  - mastodon
title: Leveraging Cloudflare for your Mastdon instance, including media in B2 object storage
description: Want to run your Mastodon instance behind Cloudflare, but put your media in B2 object storage with free egress? Here's how!
---

# Mastodon + CloudFlare + B2 Object Storage = free egress

When setting up my [Mastodon instance](https://so.fnky.nz), I jumped directly to storing all media in object storage (*Backblaze B2, in my case*), because I didn't want to allocate / estimate local storage requirements.

This turned out to be a great decision, as my media bucket quickly grew to over 100GB, but as a result, all of my media was served behind URLs like `https://f007.backblaze.com/file/something/something-else/another-something.jpg`, and could *technically* be scraped without using my Mastodon URL.

Here's how to improve this, and also serve your Mastodon instance from behind a CloudFlare proxy...

<!-- more -->

## How to CDN Mastodon with Cloudflare

After stumbling across some [#mastoadmin](https://so.fnky.nz/tags/mastoadmin) posts re the "[Bandwidth Alliance](https://www.backblaze.com/b2/solutions/content-delivery.html)", I discovered that CloudFlare and Backblaze have an agreement, under which egress traffic from Backblaze B2 buckets is free, provided they're fronted by CloudFlare's CDN.

Not knowing up-front how much I'd be using the media storage, I felt that this was a sensible idea. I also wanted my media URLs to be more "branded" that the default B2 bucket URLs.

I found some [instructions](https://www.backblaze.com/blog/free-image-hosting-with-cloudflare-transform-rules-and-backblaze-b2/) by the BackBlaze team on how to implement CloudFlare caching of B2 buckets using a custom domain, using CloudFlare's transform rules.

The initial config based on the transform rule linked above worked great, when my instance was **not** being proxied by CloudFlare. As soon as I enabled proxying for my instance, I'd get weird 404s when trying to access Mastodon.

## Try not to transform non-media URLs!

It turned out (*as I discovered after turning on access log debugging in Traefik*) that the above transform rule was applied to **all** traffic hitting my DNS name, and happily transforming **every** URL requested from Mastodon!

I made the change illustrated below, which resolved the issue, and now permits the Mastodon web components to be proxied behind CloudFlare, but also allows me to serve my media behind the B2 bucket, with a nicely-branded FQDN:

![Screenshot of transform rule for Mastodon B2 image hosting](/images/blog/mastodon_cloudflare_transform_rules.png)

## Success, #dogstodon 🐶

Now I'm one step closer to a resilient Mastodon instance which can hopefully survive the occasional traffic spike / DOS when I post something **really amazingly** interesting, like my photo-bombing dog[^1]...

<iframe src="https://so.fnky.nz/@funkypenguin/109396952935616062/embed" class="mastodon-embed" style="max-width: 100%; border: 0" width="400" allowfullscreen="allowfullscreen"></iframe><script src="https://so.fnky.nz/embed.js" async="async"></script>

[^1]: Her name is Jessie, she's a cross Labrador / Rhodesian Ridgeback, and she was just over 1 year old at the time of this photobombing! 🐾

--8<-- "blog-footer.md"
