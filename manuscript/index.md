# What is this?

Funky Penguin's "**[Geek Cookbook](https://geek-cookbook.funkypenguin.co.nz)**" is a collection of how-to guides for establishing your own container-based self-hosting platform, using either [Docker Swarm](/ha-docker-swarm/design/) or [Kubernetes](/kubernetes/start/). 

Running such a platform enables you to run self-hosted tools such as [AutoPirate](/recipes/autopirate/) (*Radarr, Sonarr, NZBGet and friends*), [Plex][plex], [NextCloud][nextcloud], and includes elements such as:

* [Automatic SSL-secured access](/ha-docker-swarm/traefik/) to all services (*with LetsEncrypt*)
* [SSO / authentication layer](/ha-docker-swarm/traefik-forward-auth/) to protect unsecured / vulnerable services
* [Automated backup](/recipes/elkarbackup/) of configuration and data
* [Monitoring and metrics](/recipes/swarmprom/) collection, graphing and alerting

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

I want your [patronage][patreon], either in the financial sense, or as a member of our [friendly geek community][discord] (*or both!*)

### Get in touch 👋

* Come and say hi to me and the friendly geeks in the [Discord][discord] chat or the [Discourse][discourse] forums - say hi, ask a question, or suggest a new recipe!
* Tweet me up, I'm [@funkypenguin][twitter]! 🐦
* [Contact me][contact] by a variety of channels

### Buy my book 📖

I'm also publishing the Geek Cookbook as a formal eBook (*PDF, mobi, epub*), on Leanpub (https://leanpub.com/geek-cookbook). Buy it for as little as $5 (_which is really just a token gesture of support, since all the content is available online anyway!_) or pay what you think it's worth!

### [Patronize][patreon] / [Sponsor][github_sponsor]  me ❤️

The best way to support this work is to become a [GitHub Sponsor](https://github.com/sponsors/funkypenguin) / [Patreon patron][patreon] (_for as little as $1/month!_) - You get :

* warm fuzzies,
* access to the pre-mix repo,
* an anonymous plug you can pull at any time,
* and a bunch more loot based on tier

.. and I get some pocket money every month to buy wine, cheese, and cryptocurrency! 🍷 💰

Impulsively **[click here (NOW quick do it!)][patreon]** to patronize me, or instead thoughtfully and analytically review my GitHub page **[here][github_sponsor]** and make up your own mind.


### Work with me 🤝

Need some Cloud / Microservices / DevOps / Infrastructure design work done? I'm a full-time [AWS-certified][aws_cert] consultant, this stuff is my bread and butter! :bread: :fork_and_knife: [Get in touch][contact], and let's talk business!

[plex]:	            https://www.plex.tv/
[owncloud]:	        https://owncloud.org/
[wordpress]:	    https://wordpress.org/
[ghost]:	        https://ghost.io/
[discord]:          http://chat.funkypenguin.co.nz
[patreon]:	        https://www.patreon.com/bePatron?u=6982506
[github_sponsor]:   https://github.com/sponsors/funkypenguin
[discourse]:	    https://discourse.geek-kitchen.funkypenguin.co.nz/
[twitter]:	        https://twitter.com/funkypenguin
[contact]:	        https://www.funkypenguin.co.nz
[aws_cert]:	        https://www.certmetrics.com/amazon/public/badge.aspx?i=4&t=c&d=2019-02-22&ci=AWS00794574
