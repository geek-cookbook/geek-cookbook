---
title: Install nginx ingress controller into Kubernetes with Flux
---
# Nginx Ingress Controller for Kubernetes - the "flux way"

The [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) is the grandpappy of Ingress Controllers, with releases dating back ot at least 2016. Of course, Nginx itself is a battle-tested rock, [released in 2004](https://en.wikipedia.org/wiki/Nginx) and has been constantly updated / improved ever since.

Having such a pedigree though can make it a little awkward for the unfamiliar to configure Nginx, whereas something like [Traefik](/kubernetes/ingress/traefik/), being newer-on-the-scene, is more user-friendly, and offers (*among other features*) a free **dashboard**. (*Nginx's dashboard is only available in the commercial Nginx+ package, which is a [monumental PITA](https://www.nginx.com/blog/deploying-nginx-nginx-plus-docker/) to run*)

Nginx Ingress Controller does make for a nice, simple "default" Ingress controller, if you don't want to do anything fancy.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] A [load-balancer](/kubernetes/loadbalancer/) solution (*either [k3s](/kubernetes/loadbalancer/k3s/) or [MetalLB](/kubernetes/loadbalancer/metallb/)*)

    Optional:

    * [x] [Cert-Manager](/kubernetes/ssl-certificates/cert-manager/) deployed to request/renew certificates
    * [x] [External DNS](/kubernetes/external-dns/) configured to respond to ingresses, or with a wildcard DNS entry

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `bootstrap/namespaces/namespace-nginx-ingress-controller.yaml`:

??? example "Example NameSpace (click to expand)"
    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: nginx-ingress-controller
    ```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. In this case, we're using the (*prolific*) [bitnami chart repository](https://github.com/bitnami/charts/tree/master/bitnami), so per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `bootstrap/helmrepositories/helmrepository-bitnami.yaml`:

??? example "Example HelmRepository (click to expand)"
    ```yaml
    apiVersion: source.toolkit.fluxcd.io/v1beta1
    kind: HelmRepository
    metadata:
      name: bitnami
      namespace: flux-system
    spec:
      interval: 15m
      url: https://charts.bitnami.com/bitnami
    ```

### Kustomization

Now that the "global" elements of this deployment (*Namespace and HelmRepository*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/nginx-ingress-controller`. I create this example Kustomization in my flux repo at `bootstrap/kustomizations/kustomization-nginx-ingress-controller.yaml`:

??? example "Example Kustomization (click to expand)"
    ```yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
    kind: Kustomization
    metadata:
      name: nginx-ingress-controller
      namespace: flux-system
    spec:
      interval: 15m
      path: ./nginx-ingress-controller
      prune: true # remove any elements later removed from the above path
      timeout: 2m # if not set, this defaults to interval duration, which is 1h
      sourceRef:
        kind: GitRepository
        name: flux-system
      validation: server
      healthChecks:
        - apiVersion: apps/v1
          kind: Deployment
          name: nginx-ingress-controller
          namespace: nginx-ingress-controller

    ```

### ConfigMap

Now we're into the nginx-ingress-controller-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/bitnami/charts/blob/master/bitnami/nginx-ingress-controller/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo at `nginx-ingress-controller/configmap-nginx-ingress-controller-helm-chart-value-overrides.yaml`:

??? example "Example ConfigMap (click to expand)"
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      creationTimestamp: null
      name: nginx-ingress-controller-helm-chart-value-overrides
      namespace: nginx-ingress-controller
    data:
      values.yaml: |-
        # paste chart values.yaml (indented) here and alter as required
    ```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration. It may not be necessary to change anything.

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy nginx-ingress-controller into the cluster, with the config and extra ConfigMap we defined above. I save this in my flux repo as `nginx-ingress-controller/helmrelease-nginx-ingress-controller.yaml`:

??? example "Example HelmRelease (click to expand)"
    ```yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: nginx-ingress-controller
      namespace: nginx-ingress-controller
    spec:
      chart:
        spec:
          chart: nginx-ingress-controller
          version: 9.x
          sourceRef:
            kind: HelmRepository
            name: bitnami
            namespace: flux-system
      interval: 15m
      timeout: 5m
      releaseName: nginx-ingress-controller
      valuesFrom:
      - kind: ConfigMap
        name: nginx-ingress-controller-helm-chart-value-overrides
        valuesKey: values.yaml # This is the default, but best to be explicit for clarity
    ```

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Deploy nginx-ingress-controller

Having committed the above to your flux repository, you should shortly see a nginx-ingress-controller kustomization, and in the `nginx-ingress-controller` namespace, a controller and a speaker pod for every node:

```bash
demo@shredder:~$ kubectl get pods -n nginx-ingress-controller
NAME                                                        READY   STATUS    RESTARTS   AGE
nginx-ingress-controller-5b849b4fbd-svbxk                   1/1     Running   0          24h
nginx-ingress-controller-5b849b4fbd-xt7vc                   1/1     Running   0          24h
nginx-ingress-controller-default-backend-867d86fb8f-t27j9   1/1     Running   0          24h
demo@shredder:~$
```

### How do I know it's working?

#### Test Service

By default, the chart will deploy nginx ingress controller's service in [LoadBalancer](/kubernetes/loadbalancer/) mode. When you use kubectl to display the service (`kubectl get services -n nginx-ingress-controller`), you'll see the external IP displayed:

```bash
demo@shredder:~$ kubectl get services -n nginx-ingress-controller
NAME                                       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
nginx-ingress-controller                   LoadBalancer   10.152.183.162   172.168.209.1    80:30756/TCP,443:30462/TCP   24h
nginx-ingress-controller-default-backend   ClusterIP      10.152.183.200   <none>           80/TCP                       24h
demo@shredder:~$
```

!!! question "Where does the external IP come from?"
    If you're using [k3s's load balancer](/kubernetes/loadbalancer/k3s/), the external IP will likely be the IP of the the nodes running k3s. If you're using [MetalLB](/kubernetes/loadbalancer/metallb/), the external IP should come from the list of addresses in the pool you allocated.

Pointing your web browser to the external IP displayed should result in the default backend page (*or an nginx-branded 404*). Congratulations, you have external access to the ingress controller! 🥳

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

Commit your changes, wait for a reconciliation, and run `kubectl get ingress -n podinfo`. You should see an ingress created matching the host defined above, and the ADDRESS value should match the service address of the nginx-ingress-controller service.

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

Are things not working as expected? Watch the nginx-ingress-controller's logs with ```kubectl logs -n nginx-ingress-controller -l app.kubernetes.io/name=nginx-ingress-controller -f```.

--8<-- "recipe-footer.md"

[^1]: The beauty of this design is that the same process will now work for any other application you deploy, without any additional manual effort for DNS or SSL setup!
