---
title: Why I use Traefik Ingress Controller
description: Among other advantages, I no longer need to replicate SSL certificate secrets for nginx-ingress-controller to consume, once-per-namespace!
---
# Traefik Ingress Controller

Unlike grumpy ol' man [Nginx](/kubernetes/ingress/nginx/) :older_man:, Traefik, a microservice-friendly reverse proxy, is relatively fresh in the "cloud-native" space, having been "born" :baby_bottle: [in the same year that Kubernetes was launched](https://techcrunch.com/2020/09/23/five-years-after-creating-traefik-application-proxy-open-source-project-hits-2b-downloads/).

Traefik natively includes some features which Nginx lacks:

* [x] Ability to use cross-namespace TLS certificates (*this may be accidental, but it totally works currently*)
* [x] An elegant "middleware" implementation allowing certain requests to pass through additional layers of authentication
* [x] A beautiful dashboard

![Traefik Screenshot](/images/traefik.png){ loading=lazy }

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] A [load-balancer](/kubernetes/loadbalancer/) solution (*either [k3s](/kubernetes/loadbalancer/k3s/) or [MetalLB](/kubernetes/loadbalancer/metallb/)*)

    Optional:

    * [x] [Cert-Manager](/kubernetes/ssl-certificates/cert-manager/) deployed to request/renew certificates
    * [x] [External DNS](/kubernetes/external-dns/) configured to respond to ingresses, or with a wildcard DNS entry

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-traefik.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. In this case, we're using the official [Traefik helm chart](https://github.com/traefik/traefik-helm-chart), so per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/helmrepositories/helmrepository-traefik.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: traefik
  namespace: flux-system
spec:
  interval: 15m
  url: https://helm.traefik.io/traefik
```

### Kustomization

Now that the "global" elements of this deployment (*Namespace and HelmRepository*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/traefik`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-traefik.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: traefik
  namespace: flux-system
spec:
  interval: 15m
  path: ./traefik
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  validation: server
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: traefik
      namespace: traefik

```

### ConfigMap

Now we're into the traefik-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 tabs (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="/traefik/configmap-traefik-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: traefik-helm-chart-value-overrides
  namespace: traefik
data:
  values.yaml: |-  # (1)!
    # <upstream values go here>
```

1. Paste in the contents of the upstream `values.yaml` here, intended 4 spaces, and then change the values you need as illustrated below.

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration. It may not be necessary to change anything.

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy traefik into the cluster, with the config and extra ConfigMap we defined above. I save this in my flux repo as `traefik/helmrelease-traefik.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: traefik
  namespace: traefik
spec:
  chart:
    spec:
      chart: traefik
      version: 10.x # (1)!
      sourceRef:
        kind: HelmRepository
        name: traefik
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: traefik
  valuesFrom:
  - kind: ConfigMap
    name: traefik-helm-chart-value-overrides
    valuesKey: values.yaml # This is the default, but best to be explicit for clarity
```

1. Use `9.x` for Kubernetes versions older than 1.22, as described [here](https://github.com/traefik/traefik-helm-chart/tree/master/traefik#kubernetes-version-support).

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Deploy traefik

Having committed the above to your flux repository, you should shortly see a traefik kustomization, and in the `traefik` namespace, a controller and a speaker pod for every node:

```bash
demo@shredder:~$ kubectl get pods -n traefik
NAME                                                        READY   STATUS    RESTARTS   AGE
traefik-5b849b4fbd-svbxk                   1/1     Running   0          24h
traefik-5b849b4fbd-xt7vc                   1/1     Running   0          24h
demo@shredder:~$
```

### How do I know it's working?

#### Test Service

By default, the chart will deploy Traefik in [LoadBalancer](/kubernetes/loadbalancer/) mode. When you use kubectl to display the service (`kubectl get services -n traefik`), you'll see the external IP displayed:

```bash
demo@shredder:~$ kubectl get services -n traefik
NAME                                       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
traefik                   LoadBalancer   10.152.183.162   172.168.209.1    80:30756/TCP,443:30462/TCP   24h
demo@shredder:~$
```

!!! question "Where does the external IP come from?"
    If you're using [k3s's load balancer](/kubernetes/loadbalancer/k3s/), the external IP will likely be the IP of the the nodes running k3s. If you're using [MetalLB](/kubernetes/loadbalancer/metallb/), the external IP should come from the list of addresses in the pool you allocated.

Pointing your web browser to the external IP displayed should result in a 404 page. Congratulations, you have external access to the Traefik ingress controller! 🥳

#### Test Ingress

Still, you didn't deploy an ingress controller to look at 404 pages! If you used my [template repository](https://github.com/geek-cookbook/template-flux) to start off your [flux deployment strategy](/kubernetes/deployment/flux/), then the podinfo helm chart has already been deployed. By default, the podinfo configmap doesn't deploy an Ingress, but you can change this using the magic of GitOps... 🪄

Edit your podinfo helmrelease configmap (`/podinfo/configmap-podinfo-helm-chart-value-overrides.yaml`), and change `ingress.enabled` to `true`, and set the host name to match your local domain name (*already configured using [External DNS](/kubernetes/external-dns/)*):

``` yaml hl_lines="2 8"
    ingress:
      enabled: false
      className: ""
      annotations: {}
        # kubernetes.io/ingress.class: nginx
        # kubernetes.io/tls-acme: "true"
      hosts:
        - host: podinfo.local
```

To:

``` yaml hl_lines="2 8"
    ingress:
      enabled: false
      className: ""
      annotations: {}
        # kubernetes.io/ingress.class: nginx
        # kubernetes.io/tls-acme: "true"
      hosts:
        - host: podinfo.<your domain name>
```

Commit your changes, wait for a reconciliation, and run `kubectl get ingress -n podinfo`. You should see an ingress created matching the host defined above, and the ADDRESS value should match the service address of the traefik service.

```bash
root@cn1:~# kubectl get ingress -A
NAMESPACE               NAME                                 CLASS    HOSTS                                  ADDRESS        PORTS     AGE
podinfo                 podinfo                              <none>   podinfo.example.com                    172.168.209.1   80, 443   91d
```

!!! question "Why is there no class value?"
    You don't **have** to define an ingress class if you only have one **class** of ingress, since typically your ingress controller will assume the default class. When you run multiple ingress controllers (say, nginx **and** [traeifk](/kubernetes/ingress/traefik/), or multiple nginx instances with different access controls) then classes become more important.

Now assuming your [DNS is correct](/kubernetes/external-dns/), you should be able to point your browser to the hostname you chose, and see the beautiful podinfo page! 🥳🥳

#### Test SSL

Ha, but we're not done yet! We have exposed a service via our load balancer, we've exposed a route to a service via an Ingress, but let's get rid of that nasty "insecure" message in the browser when using HTTPS...

Since you setup [SSL certificates,](/kubernetes/ssl-certificates/) including [secret-replicator](/kubernetes/ssl-certificates/secret-replicator/), you should end up with a `letsencrypt-wildcard-cert` secret in every namespace, including `podinfo`.

So once again, alter the podinfo ConfigMap to change this:

```yaml hl_lines="2 4"
      tls: []
      #  - secretName: chart-example-tls
      #    hosts:
      #      - chart-example.local
```

To this:

```yaml hl_lines="2 4"
      tls:
       - secretName: letsencrypt-wildcard-cert
         hosts:
           - podinfo.<your domain name>
```

Commit your changes, wait for the reconciliation, and the next time you point your browser at your ingress, you should get a beautiful, valid, officially-signed SSL certificate[^1]! 🥳🥳🥳

### Troubleshooting

Are things not working as expected? Watch the traefik's logs with ```kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f```.

--8<-- "recipe-footer.md"

[^1]: The beauty of this design is that the same process will now work for any other application you deploy, without any additional manual effort for DNS or SSL setup!
