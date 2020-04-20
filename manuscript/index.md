# What is this?

Funky Penguin's "**[Geek Cookbook][1]**" is a collection of how-to guides for establishing your own container-based self-hosting platform, using either [Docker Swarm][2] or [Kubernetes][3]. 

Running such a platform enables you to run self-hosted tools such as [AutoPirate][4] (*Radarr, Sonarr, NZBGet and friends*), [Plex][5], [NextCloud][6], and includes elements such as:

* [Automatic SSL-secured access][7] to all services (*with LetsEncrypt*)
* [SSO / authentication layer][8] to protect unsecured / vulnerable services
* [Automated backup][9] of configuration and data
* [Monitoring and metrics][10] collection, graphing and alerting

Recent updates and additions are posted on the [CHANGELOG][11], and there's a friendly community of like-minded geeks in the [Discord server][12].

## Who is this for?

You already have a familiarity with concepts such as [virtual][13] [machines][14], [Docker][15] containers, [LetsEncrypt SSL certificates][16], databases, and command-line interfaces.

You've probably played with self-hosting some mainstream apps yourself, like [Plex][17], [OwnCloud][18], [Wordpress][19] or even [SandStorm][20].

## Why should I read this?

So if you're familiar enough with the concepts above, and you've done self-hosting before, why would you read any further?

1. You want to upskill. You want to work with container orchestration, Prometheus and Grafana, Kubernetes
2. You want to play. You want a safe sandbox to test new tools, keeping the ones you want and tossing the ones you don't.
3. You want reliability. Once you go from __playing__ with a tool to actually __using__ it, you want it to be available when you need it. Having to "*quickly ssh into the basement server and restart plex*" doesn't cut it when you finally convince your wife to sit down with you to watch sci-fi.

## What have you done for me lately? (CHANGELOG)

Check out recent change at [CHANGELOG][21]

## What do you want from me?

I want your [patronage][22], either in the financial sense, or as a member of our [friendly geek community][23] (*or both!*)

### Get in touch 👋

* Come and say hi to me and the friendly geeks in the [Discord][24] chat or the [Discourse][25] forums - say hi, ask a question, or suggest a new recipe!
* Tweet me up, I'm [@funkypenguin][26]! 🐦
* [Contact me][27] by a variety of channels

### Buy my book 📖

I'm also publishing the Geek Cookbook as a formal eBook (*PDF, mobi, epub*), on Leanpub (https://leanpub.com/geek-cookbook). Buy it for as little as $5 (_which is really just a token gesture of support, since all the content is available online anyway!_) or pay what you think it's worth!

### Donate / [Support me 💰][28]

The best way to support this work is to become a [Patreon patron][29] (_for as little as $1/month!_) - You get :

* warm fuzzies,
* access to the pre-mix repo,
* an anonymous plug you can pull at any time,
* and a bunch more loot based on tier

.. and I get some pocket money every month to buy wine, cheese, and cryptocurrency! 🍷 💰

Impulsively **[click here (NOW quick do it!)][30]** to patronize me, or instead thoughtfully and analytically review my Patreon page / history **[here][31]** and make up your own mind.


### Engage me 🏢

Need some Cloud / Microservices / DevOps / Infrastructure design work done? I'm a full-time [AWS-certified][32] consultant, this stuff is my bread and butter! :bread: :fork\_and\_knife: [Contact][33] me and let's talk!

[1]:	https://geek-cookbook.funkypenguin.co.nz
[2]:	/ha-docker-swarm/design/
[3]:	/kubernetes/start/
[4]:	/recipes/autopirate/
[5]:	/recipes/plex/
[6]:	/recipes/nextcloud/
[7]:	/ha-docker-swarm/traefik/
[8]:	/ha-docker-swarm/traefik-forward-auth/
[9]:	/recipes/elkarbackup/
[10]:	/recipes/swarmprom/
[11]:	/CHANGELOG/
[12]:	http://chat.funkypenguin.co.nz
[13]:	https://libvirt.org/
[14]:	https://www.virtualbox.org/
[15]:	https://www.docker.com/
[16]:	https://letsencrypt.org/
[17]:	https://www.plex.tv/
[18]:	https://owncloud.org/
[19]:	https://wordpress.org/
[20]:	https://sandstorm.io/
[21]:	/CHANGELOG/
[22]:	https://www.patreon.com/bePatron?u=6982506
[23]:	http://chat.funkypenguin.co.nz
[24]:	http://chat.funkypenguin.co.nz
[25]:	https://discourse.geek-kitchen.funkypenguin.co.nz/
[26]:	https://twitter.com/funkypenguin
[27]:	https://www.funkypenguin.co.nz/contact/
[28]:	https://www.patreon.com/funkypenguin
[29]:	https://www.patreon.com/bePatron?u=6982506
[30]:	https://www.patreon.com/bePatron?u=6982506
[31]:	https://www.patreon.com/funkypenguin
[32]:	https://www.certmetrics.com/amazon/public/badge.aspx?i=4&t=c&d=2019-02-22&ci=AWS00794574
[33]:	https://www.funkypenguin.co.nz/contact/