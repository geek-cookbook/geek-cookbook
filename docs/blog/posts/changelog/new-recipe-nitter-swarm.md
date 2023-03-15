---
date: 2023-03-15
categories:
  - CHANGELOG
tags:
  - nitter
links:
  - Nitter recipe: recipes/nitter.md
description: New Recipe Added - Nomie - quantified-self tracker with couchdb multi-device sync
title: Added recipe for Nitter on Docker Swarm
image: /images/nitter.png
recipe: Nitter
---

# Added recipe for {{ page.meta.recipe }} (swarm)

Are you becoming increasingly wary of Twitter, [post-space-Karen](https://knowyourmeme.com/editorials/guides/who-is-space-karen-and-why-is-the-nickname-trending-on-twitter)? Try Nitter, a (*read-only*) private frontend to Twitter, supporting username and keyword search, with geeky features like RSS and theming!

<!-- more -->

![Screenshot of {{ page.meta.recipe }}]({{ page.meta.image }}){ loading=lazy }

[Nitter](https://github.com/zedeus/nitter) is a free and open source alternative Twitter front-end focused on privacy and performance, with features including:

:white_check_mark: No JavaScript or ads<br/>
:white_check_mark: All requests go through the backend, client never talks to Twitter<br/>
:white_check_mark: Prevents Twitter from tracking your IP or JavaScript fingerprint<br/>
:white_check_mark: Uses Twitter's unofficial API (*no rate limits or developer account required*)<br/>
:white_check_mark: Lightweight (for @nim_lang, 60KB vs 784KB from twitter.com)<br/>
:white_check_mark: RSS feeds, Themes, Mobile support (*responsive design*)<br/>

See the [recipe][nitter] for more!

--8<-- "common-links.md"
