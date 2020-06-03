# Kubernetes Dashboard

Yes, Kubernetes is complicated. There are lots of moving parts, and debugging _what's_ gone wrong and _why_, can be challenging.

Fortunately, to assist in day-to-day operation of our cluster, and in the occasional "how-did-that-ever-work" troubleshooting, we have available to us, the mighty **[Kubernetes Dashboard](https://github.com/kubernetes/dashboard)**:

![Kubernetes Dashboard Screenshot](https://geek-cookbook.funkypenguin.co.nz/images/kubernetes-dashboard.png)

Using the dashboard, you can:

* Visual cluster load, pod distribution
* Examine Kubernetes objects, such as Deployments, Daemonsets, ConfigMaps, etc
* View logs
* Deploy new YAML manifests
* Lots more!

## Ingredients

1. A [Kubernetes Cluster](https://geek-cookbook.funkypenguin.co.nz/kubernetes/design/), with
2. OIDC-enabled authentication
3. An Ingress Controller ([Traefik Ingress](https://geek-cookbook.funkypenguin.co.nz/kubernetes/traefik/) or [NGinx Ingress](https://geek-cookbook.funkypenguin.co.nz/kubernetes/nginx-ingress/)) 
4. A DNS name for your dashboard instance (*dashboard.example.com*, below) pointing to your [load balancer](https://geek-cookbook.funkypenguin.co.nz/kubernetes/loadbalancer/), fronting your ingress controller
5. A [KeyCloak](https://geek-cookbook.funkypenguin.co.nz/recipes/keycloak/) instance for authentication

## Preparation


### Access Kanboard

At this point, you should be able to access your instance on your chosen DNS name (*i.e. https://dashboard.example.com*)


## Chef's Notes

1. The simplest deployment of Kanboard uses the default SQLite database backend, stored on the persistent volume. You can convert this to a "real" database running MySQL or PostgreSQL, and running an an additional database pod and service. Contact me if you'd like further details ;)