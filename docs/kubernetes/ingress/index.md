---
description: What is a Kubernetes Ingress?
---
# Ingresses

In Kubernetes, an Ingress is a way to describe how to route traffic coming **into** the cluster, so that (*for example*) `https://radarr.example.com` will end up on a [Radarr][radarr] pod, but `https://sonarr.example.com` will end up on a [Sonarr][sonarr] pod.

![Ingress illustration](/images/ingress.jpg)

There are many popular Ingress Controllers, we're going to cover two equally useful options:

1. [Traefik](/kubernetes/ingress/traefik/)
2. [Nginx](/kubernetes/ingress/nginx/)

Choose at least one of the above (*there may be valid reasons to use both!* [^1]), so that you can expose applications via Ingress.
  
{% include 'recipe-footer.md' %}

[^1]: One cluster I manage uses traefik Traefik for public services, but Nginx for internal management services such as Prometheus, etc. The idea is that you'd need one type of Ingress to help debug problems with the _other_ type!
