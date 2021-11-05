# Why Kubernetes?

My first introduction to Kubernetes was a children's story:

<!-- markdownlint-disable MD033 -->
<iframe width="560" height="315" src="https://www.youtube.com/embed/R9-SOzep73w" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Why Kubernetes?

Why would you want to Kubernetes for your self-hosted recipes, over simple Docker Swarm? Here's my personal take..

### Docker Swarm is dead

Sorry to say, but from where I sit, there's no innovation or development happening in docker swarm.

Yes, I know, after Docker Inc [sold its platform business to Mirantis in Nov 2019](https://www.mirantis.com/blog/mirantis-acquires-docker-enterprise-platform-business/), in Feb 2020 Mirantis [back-tracked](https://www.mirantis.com/blog/mirantis-will-continue-to-support-and-develop-docker-swarm/) on their original plan to sunset swarm after 2 years, and stated that they'd continue to invest in swarm. But seriously, look around. Nobody is interested in swarm right now...

... Not even Mirantis! As of Nov 2021, the Mirantis blog tag "[kubernetes](https://www.mirantis.com/tag/kubernetes/)" had 8 posts within the past month. The tag "[docker](https://www.mirantis.com/tag/docker/)" has 8 posts in the past **2 years**, the 8th being the original announcement of the Docker aquisition. The tag "[docker swarm](https://www.mirantis.com/tag/docker-swarm/)" has only 2 posts, **ever**.

Dead. [Extinct. Like the doodoo](https://youtu.be/NxnZC9L_YXE?t=47).

### Once you go Kubernetes, you can't go back

For years now, [I've provided Kubernetes design consulting](https://www.funkypenguin.co.nz/work-with-me/) to small clients and large enterprises. The implementation details in each case vary widely, but there are some primitives which I've come to take for granted, and I wouldn't easily do without. A few examples:

* **CLI drives API from anywhere**. From my laptop, I can use my credentials to manage any number of Kubernetes clusters, simply by switching kubectl "context". Each interaction is an API call against an HTTPS endpoint. No SSHing to hosts and manually running docker command as root!
* **GitOps is magic**. There are multiple ways to achieve it, but having changes you commit to a repo automatically applied to a cluster, "Just Works(tm)". The process removes so much friction from making changes that it makes you more productive, and a better "gitizen" ;P
* **Controllers are trustworthy**. I've come to trust that when I tell Kubernetes to run 3 replicas on separate hosts, to scale up a set of replicas based on CPU load metrics, or provision a blob of storage for a given workloa, that this will be done in a consistent and visible way. I'll be able to see logs / details for each action taken by the controller, and adjust my own instructions/configuration accordingly if necessary.

## Uggh, it's so complicated!

Yes, it's more complex than Docker Swarm. And that complexity can definately be a barrier, although with improved tooling, it's continually becoming less-so. However, you don't need to be a mechanic to drive a car, or a mechanic to use a chainsaw. You just need a basic understanding of some core primitives, and then you get on with using the tool to achieve your goals, without needing to know every detail about how it works!

Your end-goal is probably "*I want to reliably self-host services I care about*", and not "*I want to fully understand a complex, scalable, and highly sophisticated container orchestrator*". [^1]

So let's get on with learning how to use the tool...

## Mm.. maaaaybe, how do I start?

Primarily you need 2 things:

1. A cluster
2. A way to deploy workloads into the cluster

Practically, you need some extras too, but you can mix-and-match these.

--8<-- "recipe-footer.md"

[^1]: Of course, if you **do** enjoy understanding the intricacies of how your tools work, you're in good company!
