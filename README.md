
[cookbookurl]: https://geek-cookbook.funkypenguin.co.nz
[discourseurl]: https://discourse.geek-kitchen.funkypenguin.co.nz
[discordurl]: http://chat.funkypenguin.co.nz
[patreonurl]: https://patreon.com/funkypenguin
[blogurl]: https://www.funkypenguin.co.nz
[twitchurl]: https://www.twitch.tv/funkypenguinz
[twitterurl]: https://twitter.com/funkypenguin
[dockerurl]: https://geek-cookbook.funkypenguin.co.nz/docker-swarm/design
[k8surl]: https://geek-cookbook.funkypenguin.co.nz/kubernetes/

<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

[![geek-cookbook](https://raw.githubusercontent.com/geek-cookbook/autopenguin/master/images/readme_header.png)][cookbookurl]
[![Discord](https://img.shields.io/discord/396055506072109067?color=black&label=Hot%20Sweaty%20Geeks&logo=discord&logoColor=white&style=for-the-badge)][discordurl]
[![Forums](https://img.shields.io/discourse/topics?color=black&label=Forums&logo=discourse&logoColor=white&server=https%3A%2F%2Fdiscourse.geek-kitchen.funkypenguin.co.nz&style=for-the-badge)][discourseurl]
[![Cookbook](https://img.shields.io/badge/Recipes-44-black?style=for-the-badge&color=black)][cookbookurl]
[![Twitch Status](https://img.shields.io/twitch/status/funkypenguinnz?style=for-the-badge&label=LiveGeeking&logoColor=white&logo=twitch)][twitchurl]

:wave: Welcome, traveller!
> The [Geek Cookbook][cookbookurl] is a collection of geek-friendly "recipes" to run popular applications on [Docker Swarm][dockerurl] or [Kubernetes][k8surl], in a progressive, easy-to-follow format.  ***Come and [join us][discordurl], fellow geeks!*** :neckbeard:
</div>

- [What is this?](#what-is-this)
  - [Who is this for?](#who-is-this-for)
  - [Why should I read this?](#why-should-i-read-this)
  - [What have you done for me lately? (CHANGELOG)](#what-have-you-done-for-me-lately-changelog)
  - [What do you want from me?](#what-do-you-want-from-me)
    - [Get in touch 👋](#get-in-touch-)
    - [Sponsor me ❤️](#sponsor--patronizepatreon-me-️)
    - [Work with me 🤝](#work-with-me-)
  
# What is this?

Funky Penguin's "**[Geek Cookbook](https://geek-cookbook.funkypenguin.co.nz)**" is a collection of how-to guides for establishing your own container-based self-hosting platform, using either [Docker Swarm](/docker-swarm/design/) or [Kubernetes](/kubernetes/).

Running such a platform enables you to run self-hosted tools such as [AutoPirate](/recipes/autopirate/) (*Radarr, Sonarr, NZBGet and friends*), [Plex][plex], [NextCloud][nextcloud], and includes elements such as:

- [Automatic SSL-secured access](/docker-swarm/traefik/) to all services (*with LetsEncrypt*)
- [SSO / authentication layer](/docker-swarm/traefik-forward-auth/) to protect unsecured / vulnerable services
- [Automated backup](/recipes/elkarbackup/) of configuration and data
- [Monitoring and metrics](/recipes/swarmprom/) collection, graphing and alerting

Recent updates and additions are posted on the [CHANGELOG](/CHANGELOG/), and there's a friendly community of like-minded geeks in the [Discord server](http://chat.funkypenguin.co.nz).

## Who is this for?

You already have a familiarity with concepts such as virtual machines, [Docker](https://www.docker.com/) containers, [LetsEncrypt SSL certificates](https://letsencrypt.org/), databases, and command-line interfaces.

You've probably played with self-hosting some mainstream apps yourself, like [Plex][plex], [NextCloud][nextcloud], [Wordpress][wordpress] or [Ghost][ghost].

## Why should I read this?

So if you're familiar enough with the concepts above, and you've done self-hosting before, why would you read any further?

1. You want to upskill. You want to work with container orchestration, Prometheus and Grafana, Kubernetes
2. You want to play. You want a safe sandbox to test new tools, keeping the ones you want and tossing the ones you don't.
3. You want reliability. Once you go from __playing__ with a tool to actually __using__ it, you want it to be available when you need it. Having to "*quickly ssh into the basement server and restart plex*" doesn't cut it when you finally convince your wife to sit down with you to watch sci-fi.

## What have you done for me lately? (CHANGELOG)

Check out recent change at [CHANGELOG](/CHANGELOG/)

## What do you want from me?

I want your [support][github_sponsor], either in the [financial][github_sponsor] sense, or as a member of our [friendly geek community][discord] (*or both!*)

### Get in touch 👋

- Come and say hi to me and the friendly geeks in the [Discord][discord] chat or the [Discourse][discourse] forums - say hi, ask a question, or suggest a new recipe!
- Tweet me up, I'm [@funkypenguin][twitter]! 🐦
- [Contact me][contact] by a variety of channels

### [Sponsor][github_sponsor] / [Patronize][patreon] me ❤️

The best way to support this work is to become a [GitHub Sponsor](https://github.com/sponsors/funkypenguin) / [Patreon patron][patreon] (_for as little as $1/month!_) - You get :

- warm fuzzies,
- access to the pre-mix repo,
- an anonymous plug you can pull at any time,
- and a bunch more loot based on tier

.. and I get some pocket money every month to buy wine, cheese, and cryptocurrency! 🍷 💰

Impulsively **[click here (NOW quick do it!)][github_sponsor]** to [sponsor me][github_sponsor] via GitHub, or [patronize me via Patreon][patreon]!

### Work with me 🤝

--8<-- "work-with-me.md"

[plex]:             https://www.plex.tv/
[nextcloud]:        https://nextcloud.com/
[wordpress]:        https://wordpress.org/
[ghost]:            https://ghost.io/
[discord]:          http://chat.funkypenguin.co.nz
[patreon]:          https://www.patreon.com/bePatron?u=6982506
[github_sponsor]:   https://github.com/sponsors/funkypenguin
[github]:           https://github.com/sponsors/funkypenguin
[discourse]:        https://discourse.geek-kitchen.funkypenguin.co.nz/
[twitter]:          https://twitter.com/funkypenguin
[contact]:          https://www.funkypenguin.co.nz

