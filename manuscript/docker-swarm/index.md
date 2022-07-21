---
title: Why use Docker Swarm?
description: Using Docker Swarm to build your own container-hosting platform which is highly-available, scalable, portable, secure and automated! 💪
---

# Why Docker Swarm?

Pop quiz, hotshot.. There's a server with containers on it. Once you run enough containers, you start to loose track of compose files / data. If the host fails, all your services are unavailable. What do you do? **WHAT DO YOU DO**?[^1]

<iframe width="560" height="315" src="https://www.youtube.com/embed/Ug2hLQv6WeY" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

You too, action-geek, can save the day, by...

1. Enable [Docker Swarm mode](/site/docker-swarm/docker-swarm-mode/) (*even just on one node*)[^2]
2. Store your swarm configuration and application data in an [orderly and consistent structure](/reference/data_layout)
3. Expose all your services consistently using [Traefik](/docker-swarm/traefik/) with optional [additional per-service authentication][tfa]

Then you can really level-up your geek-fu, by:

4. Making your Docker Swarm highly with [keepalived](/docker-swarm/keepalived/)
5. Setup [shared storage](/docker-swarm/shared-storage-ceph/) to eliminate SPOFs
6. [Backup](/recipes/duplicity/) your stuff automatically

Ready to enter the matrix? Jump in on one of the links above, or start reading the [design](/docker-swarm/design/)

--8<-- "recipe-footer.md"

[^1]: This was an [iconic movie](https://www.imdb.com/title/tt0111257/). It even won 2 Oscars! (*but not for the acting*)
[^2]: There are significant advantages to using Docker Swarm, even on just a single node.