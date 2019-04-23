# Why Kubernetes?

My first introduction to Kubernetes was a children's story:

<iframe width="560" height="315" src="https://www.youtube.com/embed/4ht22ReBjno" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Wait, what?

Why would you want to use Kubernetes for your self-hosted recipes over simple Docker Swarm? Here's my personal take..

I use Docker swarm both at home (_on a single-node swarm_), and on a trio of Ubuntu 16.04 VPSs in a shared lab OpenStack environment.

In both cases above, I'm responsible for maintaining the infrastructure supporting Docker - either the physical host, or the VPS operating systems.

I started experimenting with Kubernetes as a plan to improve the reliability of my cryptocurrency mining pools (_the contended lab VPSs negatively impacted the likelihood of finding a block_), and as a long-term replacement for my aging home server.

What I enjoy about building recipes and self-hosting is **not** the operating system maintenance, it's the tools and applications that I can quickly launch in my swarms. If I could **only** play with the applications, and not bother with the maintenance, I totally would.

Kubernetes (_on a cloud provider, mind you!_) does this for me. I feed Kubernetes a series of YAML files, and it takes care of all the rest, including version upgrades, node failures/replacements, disk attach/detachments, etc.

## Uggh, it's so complicated!

Yes, but that's a necessary sacrifice for the maturity, power and flexibility it offers. Like docker-compose syntax, Kubernetes uses YAML to define its various, interworking components.

Let's talk some definitions. Kubernetes.io provides a [glossary](https://kubernetes.io/docs/reference/glossary/?fundamental=true). My definitions are below:

* **Node** : A compute instance which runs docker containers, managed by a cluster master.

* **Cluster** : One or more "worker nodes" which run containers. Very similar to a Docker Swarm node. In most cloud provider deployments, the [master node for your cluster is provided free of charge](https://www.sdxcentral.com/articles/news/google-eliminates-gke-management-fees-kubernetes-clusters/2017/11/), but you don't get to access it.

* **Pod** : A collection of one or more the containers. If a pod runs multiple containers, these containers always run on the same node.

* **Deployment** : A definition of a desired state. I.e., "I want a pod with containers A and B running". The Kubernetes master then ensures that any changes necessary to maintain the state are taken. (_I.e., if a pod crashes, but is supposed to be running, a new pod will be started_)

* **Service** : Unlike Docker Swarm, service discovery is not _built in_ to Kubernetes. For your pods to discover each other (say, to have "webserver" talk to "database"), you create a service for each pod, and refer to these services when you want your containers (_in pods_) to talk to each other. Complicated, yes, but the abstraction allows you to do powerful things, like auto-scale-up a bunch of database "pods" behind a service called "database", or perform a rolling container image upgrade with zero impact.

* **External access** : Services not only allow pods to discover each other, but they're also the mechanism through which the outside world can talk to a container. At the simplest level, this is akin to exposing a container port on a docker host.

* **Ingress** : When mapping ports to applications is inadequate (think virtual web hosts), an ingress is a sort of "inbound router" which can receive requests on one port (i.e., HTTPS), and forward them to a variety of internal pods, based on things like VHOST, etc. For us, this is the functional equivalent of what Traefik does in Docker Swarm. In fact, we use a Traefik Ingress in Kubernetes to accomplish the same.

* **Persistent Volume** : A virtual disk which is attached to a pod, storing persistent data. Meets the requirement for shared storage from Docker Swarm. I.e., if a persistent volume (PV) is bound to a pod, and the pod dies and is recreated, or get upgraded to a new image, the PV the data is bound to the new container. PVs can be "claimed" in a YAML definition, so that your Kubernetes provider will auto-create a PV when you launch your pod. PVs can be snapshotted.

* **Namespace** : An abstraction to separate a collection of pods, services, ingresses, etc. A "virtual cluster within a cluster". Can be used for security, or simplicity. For example, since we don't have individual docker stacks anymore, if you commonly name your database container "db", and you want to deploy two applications which both use a database container, how will you name your services? Use namespaces to keep each application ("nextcloud" vs "kanboard") separate. Namespaces also allow you to allocate resources **limits** to the aggregate of containers in a namespace, so you could, for example, limit the "nextcloud" namespace to 2.3 CPUs and 1200MB RAM.

## Mm.. maaaaybe, how do I start?

If you're like me, and you learn by doing, either play with the examples at https://labs.play-with-k8s.com/, or jump right in by setting up a Google Cloud trial (_you get $300 credit for 12 months_), or a small cluster on [Digital Ocean](/kubernetes/digitalocean/).

If you're the learn-by-watching type, just search for "Kubernetes introduction video". There's a **lot** of great content available.

## I'm ready, gimme some recipes!

As of Jan 2019, our first (_and only!_) Kubernetes recipe is a WIP for the Mosquitto [MQTT](/recipes/mqtt/) broker. It's a good, simple starter if you're into home automation (_shoutout to [Home Assistant](/recipes/homeassistant/)!_), since it only requires a single container, and a simple NodePort service.

I'd love for your [feedback](/support/) on the Kubernetes recipes, as well as suggestions for what to add next. The current rough plan is to replicate the Chef's Favorites recipes (_see the left-hand panel_) into Kubernetes first.

## Move on..

Still with me? Good. Move on to reviewing the design elements

* Start (this page) - Why Kubernetes?
* [Design](/kubernetes/design/) - How does it fit together?
* [Cluster](/kubernetes/cluster/) - Setup a basic cluster
* [Load Balancer](/kubernetes/loadbalancer/) - Setup inbound access
* [Snapshots](/kubernetes/snapshots/) - Automatically backup your persistent data
* [Helm](/kubernetes/helm/) - Uber-recipes from fellow geeks
* [Traefik](/kubernetes/traefik/) - Traefik Ingress via Helm


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
