# Helm

[Helm](https://github.com/helm/helm) is a tool for managing Kubernetes "charts" (_think of it as an uber-polished collection of recipes_). Using one simple command, and by tweaking one simple config file (values.yaml), you can launch a complex stack. There are many publicly available helm charts for popular packages like [elasticsearch](https://github.com/helm/charts/tree/master/stable/elasticsearch), [ghost](https://github.com/helm/charts/tree/master/stable/ghost), [grafana](https://github.com/helm/charts/tree/master/stable/grafana), [mediawiki](https://github.com/helm/charts/tree/master/stable/mediawiki), etc.

![Kubernetes Snapshots](/images/kubernetes-helm.png)

## Ingredients

1. [Kubernetes cluster](/kubernetes/cluster/)
2. Geek-Fu required : 🐤 (_easy - copy and paste_)

## Preparation

### Install Helm

This section is from the Helm README:

Binary downloads of the Helm client can be found on [the Releases page](https://github.com/helm/helm/releases/latest).

Unpack the `helm` binary and add it to your PATH and you are good to go!

If you want to use a package manager:

- [Homebrew](https://brew.sh/) users can use `brew install kubernetes-helm`.
- [Chocolatey](https://chocolatey.org/) users can use `choco install kubernetes-helm`.
- [Scoop](https://scoop.sh/) users can use `scoop install helm`.
- [GoFish](https://gofi.sh/) users can use `gofish install helm`.

To rapidly get Helm up and running, start with the [Quick Start Guide](https://helm.sh/docs/intro/quickstart/).

See the [installation guide](https://helm.sh/docs/intro/install/) for more options,
including installing pre-releases.


## Serving

### Initialise Helm

After installing Helm, initialise it by running ```helm init```. This will install "tiller" pod into your cluster, which works with the locally installed helm binaries to launch/update/delete Kubernetes elements based on helm charts.

That's it - not very exciting I know, but we'll need helm for the next and final step in building our Kubernetes cluster - deploying the [Traefik ingress controller (via helm)](/kubernetes/traefik/)!

## Move on..

Still with me? Good. Move on to understanding Helm charts...

* [Start](/kubernetes/) - Why Kubernetes?
* [Design](/kubernetes/design/) - How does it fit together?
* [Cluster](/kubernetes/cluster/) - Setup a basic cluster
* [Load Balancer](/kubernetes/loadbalancer/) Setup inbound access
* [Snapshots](/kubernetes/snapshots/) - Automatically backup your persistent data
* Helm (this page) - Uber-recipes from fellow geeks
* [Traefik](/kubernetes/traefik/) - Traefik Ingress via Helm


[^1]: Of course, you can have lots of fun deploying all sorts of things via Helm. Check out https://artifacthub.io for some examples.

--8<-- "recipe-footer.md"
