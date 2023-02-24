---
date: 2023-02-24
categories:
  - CHANGELOG
tags:
  - matrix
links:
  - Matrix Community: community/matrix.md
  - Slack Community: community/slack.md
description: Not into Discord? Now we're bridged to Matrix and Slack!
title: Our Discord server is now bridged to Matrix and Slack
image: /images/bridge-ception.png
---

# Not into Discord? Now we're bridged to Matrix and Slack!

Ever since dabbling in the "fediverse" with [Mastodon][review/mastodon], I've been thinking about how to archive (*"liberate"*) our community chat history from Discord, so that it's preserved in the event of a Discord "space-karen" event...

<!-- more -->

While Matrix is a powerful, open-source, federated group-chat protocol, its secret sauce is its ability bridge multiple isolated platforms together, so as to ensure cross-platform communication. For example, Matrix can bridge Discord and Slack, such that the same messages can appear in Discord, Matrix, **and** Slack:

![Screenshot of bridge-ception]({{ page.meta.image }}){ loading=lazy }

I'm planning a recipe re the (*complex*) implementation of a Matrix instance (*and associated bridges*) on Kubernetes, but in the interim, we now have:

* A community [Discord server][community/discord], bridged with...
* A communtiy [Matrix server][community/matrix], bridged with...
* A community [Slack server][community/slack]

Jump in and join the fun! :grin:

--8<-- "common-links.md"
