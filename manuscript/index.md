---
title: How I do "awesome selfhosted"
description: My collection of how-to guides and tutorials for establishing your own container-based awesome selfhosted platform, using either Docker or Kubernetes.
hide:
  - navigation # Hide navigation
  # - toc        # Hide table of contents
---

# Let's build your awesome selfhosted platform together!

Welcome, fellow geek :wave: If you're impatient, just start here :point_down:

<div class="grid cards" markdown>

-   __Dive into :material-docker:{ .docker .lg .middle } [Docker Swarm](/docker-swarm/design/)__

    ---

    The quickest way to get started, and to get your head around the basics.

-   __Kick it with :material-kubernetes:{ .kubernetes .lg .middle } [Kubernetes](/kubernetes/)__

    ---

    Been around for a while? Got a high pain threshold? Jump in!

-  __Geek out in :fontawesome-brands-discord:{ .discord .lg .middle } [Discord](http://chat.funkypenguin.co.nz)__

    ---

    Join the fun, chat with fellow geeks in realtime!

-   __Fast-track with 🚀 [Premix](/premix)!__

    ---

    Life's too short? Fast-track your stack with Premix!

</div>


## What to expect

The "*Geek Cookbook*" is a collection of how-to guides for establishing your own container-based awesome selfhosted platform, using either [Docker Swarm](/docker-swarm/design/) or [Kubernetes](/kubernetes/).

Running such a platform enables you to run selfhosted services such as the [AutoPirate](/recipes/autopirate/) (*Radarr, Sonarr, NZBGet and friends*) stack, [Plex](https://www.plex.tv/), [NextCloud](https://nextcloud.com/)etc, and includes elements such as:

* [Automatic SSL-secured access](/docker-swarm/traefik/) to all services (*with LetsEncrypt*)
* [SSO / authentication layer](/docker-swarm/traefik-forward-auth/) to protect unsecured / vulnerable services
* [Automated backup](/recipes/elkarbackup/) of configuration and data
* [Monitoring and metrics](/recipes/swarmprom/) collection, graphing and alerting

Recent updates and additions are posted on the [CHANGELOG](/CHANGELOG/), and there's a friendly community of like-minded geeks in the [Discord server](http://chat.funkypenguin.co.nz).

## How will this benefit me?

You already have a familiarity with concepts such as virtual machines, [Docker](https://www.docker.com/) containers, [LetsEncrypt SSL certificates](https://letsencrypt.org/), databases, and command-line interfaces.

You've probably played with self-hosting some mainstream apps yourself, like [Plex](https://www.plex.tv/), [NextCloud](https://nextcloud.com/), [Wordpress](https://wordpress.org/) or [Ghost](https://ghost.io/).

So if you're familiar enough with the concepts above, and you've done self-hosting before, why would you read any further?

1. You want to upskill. You want to work with container orchestration, Prometheus and Grafana, Kubernetes
2. You want to play. You want a safe sandbox to test new tools, keeping the ones you want and tossing the ones you don't.
3. You want reliability. Once you go from __playing__ with a tool to actually __using__ it, you want it to be available when you need it. Having to "*quickly ssh into the basement server and restart plex*" doesn't cut it when you finally convince your wife to sit down with you to watch sci-fi :robot:

## Testimonials

!!! quote "...how useful the recipes are for people just getting started with containers..."

    "One of the surprising realizations from following Funky Penguins cookbooks for so long is how useful the recipes are for people just getting started with containers and how it gives them real, interesting usecases to attach to their learning" - [DevOps Daniel (@DanielSHouston)](https://twitter.com/DanielSHouston/status/1213419203379773442)

!!! quote "He unblocked me on all the technical hurdles to launching my SaaS in GKE!"

    By the time I had enlisted Funky Penguin's help, I'd architected myself into a bit of a nightmare with Kubernetes. I knew what I wanted to achieve, but I'd made a mess of it. Funky Penguin (David) was able to jump right in and offer a vital second-think on everything I'd done, pointing out where things could be simplified and streamlined, and better alternatives. 

    He unblocked me on all the technical hurdles to launching my SaaS in GKE! 

    With him delivering the container/Kubernetes architecture and helm CI/CD workflow, I was freed up to focus on coding and design, which fast-tracked me to launching on time. And now I have a simple deployment process that is easy for me to execute and maintain as a solo founder. 

    I have no hesitation in recommending him for your project, and I'll certainly be calling on him again in the future.

    -- John McDowall, Founder, [kiso.io](https://kiso.io) 

## Who made this?

### 👋 Hi, I'm David

I’ve spent 20+ years working with technology. I’m a solution architect, with a broad range of experience and skills. I'm a full-time [AWS Certified Solution Architect (Professional)][cert_aws], a [CNCF-Certified Kubernetes Administrator][cert_cka], [Application Developer][cert_ckad] and [Security Specialist][cert_cks].

### What do you want from me?

I want your [support](https://github.com/sponsors/funkypenguin), either in the [financial](https://github.com/sponsors/funkypenguin) sense, or as a member of our [friendly geek community](http://chat.funkypenguin.co.nz) (*or both!*)

#### Get in touch 💬

* Come and say hi to me and the friendly geeks in the [Discord](http://chat.funkypenguin.co.nz) chat or the [Discourse](https://forum.funkypenguin.co.nz/) forums - say hi, ask a question, or suggest a new recipe!
* Tweet me up, I'm [@funkypenguin](https://twitter.com/funkypenguin)! 🐦
* [Contact me](https://www.funkypenguin.co.nz/contact/) by a variety of channels

#### [Sponsor](https://github.com/sponsors/funkypenguin) me ❤️

The best way to support this work is to become a [GitHub Sponsor](https://github.com/sponsors/funkypenguin) / [Patreon patron](https://www.patreon.com/bePatron?u=6982506). You get:

* warm fuzzies,
* access to the pre-mix repo,
* an anonymous plug you can pull at any time,
* and a bunch more loot based on tier

.. and I get some pocket money every month to buy wine, cheese, and cryptocurrency! 🍷 💰

Impulsively **[click here (NOW quick do it!)](https://github.com/sponsors/funkypenguin)** to [sponsor me](https://github.com/sponsors/funkypenguin) via GitHub, or [patronize me via Patreon](https://www.patreon.com/bePatron?u=6982506)!

#### Work with me 🤝

Need some Cloud / Microservices / DevOps / Infrastructure design work done? This stuff is my bread and butter! :bread: :fork_and_knife: [Get in touch][contact], and let's talk!



#### Buy me a coffee ☕️

A sponsorship is too much commitment, and a book is TL;DR? Hit me up with a [one-time caffine shot](https://www.buymeacoffee.com/funkypenguin)!

### Sponsored Projects

I'm supported and motivated by [GitHub Sponsors](https://github.com/sponsors/funkypenguin) and [Patreon patrons](https://www.patreon.com/funkypenguin) who have generously sponsored me.

I regularly donate to / sponsor the following projects. **Join me** in supporting these geeks, and encouraging them to continue building the ingredients for your favourite recipes!

| Project | Donate via..
| ------------- |-------------|
| [Komga](/recipes/komga/)      | [GitHub Sponsors](https://github.com/sponsors/gotson)
| [Material for MKDocs](https://squidfunk.github.io/mkdocs-material/) | [GitHub Sponsors](https://github.com/sponsors/squidfunk)
| [Calibre](https://calibre-ebook.com/) | [Credit Card](https://calibre-ebook.com/donate) / [Patreon](https://www.patreon.com/kovidgoyal) / [LibrePay](https://liberapay.com/kovidgoyal/donate)
| [LinuxServer.io](https://www.linuxserver.io) | [PayPal](https://www.linuxserver.io/donate)
| [WidgetBot's Discord Widget](https://widgetbot.io/) | [Patreon](https://www.patreon.com/widgetbot/overview)
| [Carl-bot](https://carl.gg/) | [Patreon](https://www.patreon.com/carlbot)

--8<-- "common-links.md"