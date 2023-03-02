---
date: 2023-03-02
categories:
  - CHANGELOG
tags:
  - nomie
links:
  - Nomie recipe: recipes/nomie.md
description: New Recipe Added - Nomie - quantified-self tracker with couchdb multi-device sync
title: Added recipe for Nomie on Docker Swarm
image: /images/nomie.png
---

# Added recipe for Nomie (swarm)

Do you wish you had a chart showing your exercise, weight, or pooping :poo: trends over the past month? Nomie is a beautiful life/self-tracking app, an 8-year labor of love from developer [Brandon Corbin](https://brandons.app/).

Brandon has [recently shut down]((https://nomie.app/#more)) the commercially hosted version of Nomie, but open-sourced all the code, so one of the geekier alternatives, buyoued by the still-passionate community of users, is to run your own Nomie instance...

<!-- more -->

![Screenshot of Nomie]({{ page.meta.image }}){ loading=lazy }

!!! question "It's a PWA with local storage, why self-host at all?"
    Yes, you **could** just use <https://open-nomie.github.io/>, and since the PWA stores your data in your local browser store anyway, you'd get all the functionality without having to deploy a thing. However, if you want to use Nomie from **multiple browsers**, (*i.e., your phone **and** your desktop*), you'll need a way to sync the data, which, in this case, requires your own CouchDB instance. And if you're going to self-host CouchDB, you may as well self-host the PWA too!

    To this end, in this recipe, I'll assume we want CouchDB syncing (*after all, who only uses one device these days?*)

See the [recipe][nomie] for more!

--8<-- "common-links.md"
