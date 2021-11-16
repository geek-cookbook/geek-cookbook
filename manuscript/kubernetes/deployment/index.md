---
description: Kubernetes deployment strategies
---

# Deployment

So far our Kubernetes journey has been fairly linear - your standard "geek follows instructions" sort of deal.

When it comes to a deployment methodology, there are a few paths you can take, and it's possible to "mix-and-match" if you want to (*and if you enjoy extra pain and frustration!*)

Being imperative, Kubernetes is "driven" by your definitions of an intended state. I.e., "*I want a minecraft server and a 3-node redis cluster*". The state is defined by resources (pod, deployment, PVC) etc, which you apply to the Kubernetes apiserver, normally using YAML.

Now you _could_ hand-craft some YAML files, and manually apply these to the apiserver, but there are much smarter and more scalable ways to drive Kubernetes. 

The typical methods of deploying applications into Kubernetes, sorted from least to most desirable and safe are:

1. A human applies YAML directly to the apiserver.
2. A human applies a helm chart directly to the apiserver.
3. A human updates a version-controlled set of configs, and a CI process applies YAML/helm chart directly to the apiserver.
4. A human updates a version-controlled set of configs, and a trusted process _within_ the cluster "reaches out" to the config, and applies it to itself.

In our case, #4 is achieved with [Flux](/kubernetes/deployment/flux/).
