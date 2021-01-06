# What is this thing?

Funky Penguin's "**[Geek Cookbook](https://geek-cookbook.funkypenguin.co.nz)**" is a collection of how-to guides for establishing your own container-based self-hosting platform, using either [Docker Swarm](/ha-docker-swarm/design/) or [Kubernetes](/kubernetes/start/). 

Running such a platform enables you to run self-hosted tools such as [AutoPirate](/recipes/autopirate/) (*Radarr, Sonarr, NZBGet and friends*), [Plex](https://www.plex.tv/), [NextCloud](https://nextcloud.com/), and includes elements such as:

* [Automatic SSL-secured access](/ha-docker-swarm/traefik/) to all services (*with LetsEncrypt*)
* [SSO / authentication layer](/ha-docker-swarm/traefik-forward-auth/) to protect unsecured / vulnerable services
* [Automated backup](/recipes/elkarbackup/) of configuration and data
* [Monitoring and metrics](/recipes/swarmprom/) collection, graphing and alerting

Recent updates and additions are posted on the [CHANGELOG](/CHANGELOG/), and there's a friendly community of like-minded geeks in the [Discord server](http://chat.funkypenguin.co.nz).

## Who is this for?

You already have a familiarity with concepts such as virtual machines, [Docker](https://www.docker.com/) containers, [LetsEncrypt SSL certificates](https://letsencrypt.org/), databases, and command-line interfaces.

You've probably played with self-hosting some mainstream apps yourself, like [Plex](https://www.plex.tv/), [NextCloud](https://nextcloud.com/), [Wordpress](https://wordpress.org/) or [Ghost](https://ghost.io/).

## Why should I read this?

So if you're familiar enough with the concepts above, and you've done self-hosting before, why would you read any further?

1. You want to upskill. You want to work with container orchestration, Prometheus and Grafana, Kubernetes
2. You want to play. You want a safe sandbox to test new tools, keeping the ones you want and tossing the ones you don't.
3. You want reliability. Once you go from __playing__ with a tool to actually __using__ it, you want it to be available when you need it. Having to "*quickly ssh into the basement server and restart plex*" doesn't cut it when you finally convince your wife to sit down with you to watch sci-fi.

!!! quote "...how useful the recipes are for people just getting started with containers..."

    <blockquote class="twitter-tweet"><p lang="en" dir="ltr">.<a href="https://twitter.com/funkypenguin?ref_src=twsrc%5Etfw">@funkypenguin</a> One of the surprising realizations from following Funky Penguins cookbooks <a href="https://t.co/XvZ2qLJa5N">https://t.co/XvZ2qLJa5N</a> for so long is how useful the recipes are for people just getting started with containers and how it gives them real, interesting usecases to attach to their learning</p>&mdash; DevOps Daniel (@DanielSHouston) <a href="https://twitter.com/DanielSHouston/status/1213419203379773442?ref_src=twsrc%5Etfw">January 4, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


## What have you done for me lately? (CHANGELOG)

Check out recent change at [CHANGELOG](/CHANGELOG/)

## What do you want from me?

I want your [support](https://github.com/sponsors/funkypenguin), either in the [financial](https://github.com/sponsors/funkypenguin) sense, or as a member of our [friendly geek community](http://chat.funkypenguin.co.nz) (*or both!*)

### Get in touch 👋

* Come and say hi to me and the friendly geeks in the [Discord](http://chat.funkypenguin.co.nz) chat or the [Discourse](https://discourse.geek-kitchen.funkypenguin.co.nz/) forums - say hi, ask a question, or suggest a new recipe!
* Tweet me up, I'm [@funkypenguin](https://twitter.com/funkypenguin)! 🐦
* [Contact me](https://www.funkypenguin.co.nz/contact/) by a variety of channels


### [Sponsor](https://github.com/sponsors/funkypenguin) / [Patronize](https://www.patreon.com/bePatron?u=6982506) me ❤️

The best way to support this work is to become a [GitHub Sponsor](https://github.com/sponsors/funkypenguin) / [Patreon patron](https://www.patreon.com/bePatron?u=6982506). You get:

* warm fuzzies,
* access to the pre-mix repo,
* an anonymous plug you can pull at any time,
* and a bunch more loot based on tier

.. and I get some pocket money every month to buy wine, cheese, and cryptocurrency! 🍷 💰

Impulsively **[click here (NOW quick do it!)](https://github.com/sponsors/funkypenguin)** to [sponsor me](https://github.com/sponsors/funkypenguin) via GitHub, or [patronize me via Patreon](https://www.patreon.com/bePatron?u=6982506)!


### Work with me 🤝

Need some Cloud / Microservices / DevOps / Infrastructure design work done? I'm a full-time [AWS-certified](https://www.certmetrics.com/amazon/public/badge.aspx?i=4&t=c&d=2019-02-22&ci=AWS00794574) consultant, this stuff is my bread and butter! :bread: :fork_and_knife: [Get in touch](https://www.funkypenguin.co.nz/contact/), and let's talk business!


!!! quote "He unblocked me on all the technical hurdles to launching my SaaS in GKE!"

    By the time I had enlisted Funky Penguin's help, I'd architected myself into a bit of a nightmare with Kubernetes. I knew what I wanted to achieve, but I'd made a mess of it. Funky Penguin (David) was able to jump right in and offer a vital second-think on everything I'd done, pointing out where things could be simplified and streamlined, and better alternatives. 

    He unblocked me on all the technical hurdles to launching my SaaS in GKE! 

    With him delivering the container/Kubernetes architecture and helm CI/CD workflow, I was freed up to focus on coding and design, which fast-tracked me to launching on time. And now I have a simple deployment process that is easy for me to execute and maintain as a solo founder. 

    I have no hesitation in recommending him for your project, and I'll certainly be calling on him again in the future.

    -- John McDowall, Founder, [kiso.io](https://kiso.io) 

### Buy my book 📖

I'm publishing the Geek Cookbook as a formal eBook (*PDF, mobi, epub*), on Leanpub (https://leanpub.com/geek-cookbook). Check it out!