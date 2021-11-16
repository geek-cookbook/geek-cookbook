---
description: MetalLB - Load-balancing for bare-metal Kubernetes clusters
---
# MetalLB

[MetalLB](https://metallb.universe.tf/) offers a network [load balancer](/kubernetes/load-balancer/) implementation which workes on "bare metal" (*as opposed to a cloud provider*).

MetalLB does two jobs:

1. Provides address allocation to services out of a pool of addresses which you define
2. Announces these addresses to devices outside the cluster, either using ARP/NDP (L2) or BGP (L3)


!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] If k3s is used, then it was deployed with `--disable servicelb`

    Optional:

    * [ ] Network firewall/router supporting BGP (*ideal but not required*)


## Preparation 

### Allocations

You'll need to make some decisions re IP allocations.

* What is the range of addresses you want to use for your LoadBalancer service pool? If you're using BGP, this can be a dedicated subnet (*i.e. a /24*), and if you're not, this should be a range of IPs in your existing network space for your cluster nodes (*i.e., 192.168.1.100-200*)
* If you're using BGP, pick two [private AS numbers](https://datatracker.ietf.org/doc/html/rfc6996#section-5) between 64512 and 65534 inclusively.

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this in my flux repo at `flux-system/namespaces/namespace-metallb.yaml`:

??? example "Example NameSpace (click to expand)"
    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: metallb-system
    ```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. In this case, we're using the (*prolific*) [bitnami chart repository](https://github.com/bitnami/charts/tree/master/bitnami), so per the [flux design](/kubernetes/deployment/flux/), I create this in my flux repo at `flux-system/helmrepositories/helmrepository-bitnami.yaml`:

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

Now that the "global" elements of this deployment (*Namespace and HelmRepository*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/metallb-system`. I create this Kustomization in my flux repo at `flux-system/kustomizations/kustomization-metallb.yaml`:

??? example "Example Kustomization (click to expand)"
    ```yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
    kind: Kustomization
    metadata:
      name: metallb--metallb-system
      namespace: flux-system
    spec:
      interval: 15m
      path: ./metallb-system
      prune: true # remove any elements later removed from the above path
      timeout: 2m # if not set, this defaults to interval duration, which is 1h
      sourceRef:
        kind: GitRepository
        name: flux-system
      validation: server
      healthChecks:
        - apiVersion: apps/v1
          kind: Deployment
          name: metallb-controller
          namespace: metallb-system

    ```

!!! question "What's with that screwy name?"
    > Why'd you call the kustomization `metallb--metallb-system`?

    I keep my file and object names as consistent as possible. In most cases, the helm chart is named the same as the namespace, but in some cases, by upstream chart or historical convention, the namespace is different to the chart name. MetalLB is one of these - the helmrelease/chart name is `metallb`, but the typical namespace it's deployed in is `metallb-system`. (*Appending `-system` seems to be a convention used in some cases for applications which support the entire cluster*). To avoid confusion when I list all kustomizations with `kubectl get kustomization -A`, I give these oddballs a name which identifies both the helmrelease and the namespace.


### ConfigMap (for HelmRelease)

Now we're into the metallb-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/bitnami/charts/blob/master/bitnami/metallb/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 tabs (*since they're "encapsulated" within the ConfigMap YAML*). I create this in my flux repo at `metallb/configmap-metallb-helm-chart-value-overrides.yaml`:

??? example "Example ConfigMap (click to expand)"
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      creationTimestamp: null
      name: metallb-helm-chart-value-overrides
      namespace: metallb-system
    data:
      values.yaml: |-
        ## @section Global parameters
        ## Global Docker image parameters
        ## Please, note that this will override the image parameters, including dependencies, configured to use the global value
        ## Current available global Docker image parameters: imageRegistry, imagePullSecrets and storageClass

        ## @param global.imageRegistry Global Docker image registry
        ## @param global.imagePullSecrets Global Docker registry secret names as an array
        ##
        global:
        imageRegistry: ""
        ## E.g.
        ## imagePullSecrets:
        ##   - myRegistryKeySecretName
        <snip>
        prometheus:
            ## Prometheus Operator service monitors
            ##
            serviceMonitor:
            ## @param speaker.prometheus.serviceMonitor.enabled Enable support for Prometheus Operator
            ##
            enabled: false
            ## @param speaker.prometheus.serviceMonitor.jobLabel Job label for scrape target
            ##
            jobLabel: "app.kubernetes.io/name"
            ## @param speaker.prometheus.serviceMonitor.interval Scrape interval. If not set, the Prometheus default scrape interval is used
            ##
            interval: ""
            ## @param speaker.prometheus.serviceMonitor.metricRelabelings Specify additional relabeling of metrics
            ##
            metricRelabelings: []
            ## @param speaker.prometheus.serviceMonitor.relabelings Specify general relabeling
            ##
            relabelings: []
    ```

!!! question "That's a lot of unnecessary text!"
    > Why not just paste in the subset of values I want to change?

    You know what's harder than working out which values from a 2000-line `values.yaml` to change?

    Answer: Working out what values to change when the upstream helm chart has refactored or added options! By pasting in the entirety of the upstream chart, when it comes time to perform upgrades, you can just duplicate your ConfigMap YAML, paste the new values into one of the copies, and compare them side by side to ensure your original values/decisions persist in the new chart.

Then work your way through the values you pasted, and change any which are specific to your configuration. I'd recommend changing the following:

* `existingConfigMap: metallb-config`: I prefer to set my MetalLB config independently of the chart config, so I set this to `metallb-config`, which I then define below.
* `commonAnnotations`: Anticipating the future use of Reloader to bounce applications when their config changes, I add the `configmap.reloader.stakater.com/reload: "metallb-config"` annotation to all deployed objects, which will instruct Reloader to bounce the daemonset if the ConfigMap changes.

### ConfigMap (for MetalLB)

Finally, it's time to actually configure MetalLB! As discussed above, I prefer to configure the helm chart to apply config from an existing ConfigMap, so that I isolate my application configuration from my chart configuration (*and make tracking changes easier*). In my setup, I'm using BGP against a pair of pfsense[^1] firewalls, so per the [official docs](https://metallb.universe.tf/configuration/), I use the following configuration, saved in my flux repo as `flux-system/configmap-metallb-config.yaml`:

??? example "Example ConfigMap (click to expand)"
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      namespace: metallb-system
      name: metallb-config
    data:
      config: |
        peers:
        - peer-address: 192.168.33.2  
          peer-asn: 64501
          my-asn: 64500
        - peer-address: 192.168.33.4  
          peer-asn: 64501
          my-asn: 64500
        
        address-pools:
        - name: default
          protocol: bgp
          avoid-buggy-ips: true
          addresses:
          - 192.168.32.0/24
    ```

!!! question "What does that mean?"
    In the config referenced above, I define one pool of addresses (`192.168.32.0/24`) which MetalLB is responsible for allocating to my services. MetalLB will then "advertise" these addresses to my firewalls (`192.168.33.2` and `192.168.33.4`), in an eBGP relationship where the firewalls' ASN is `64501` and MetalLB's ASN is `64500`. Provided I'm using my firewalls as my default gateway (*a VIP*), when I try to access one of the `192.168.32.x` IPs from any subnet connected to my firewalls, the traffic will be routed from the firewall to one of the cluster nodes running the pods selected by that service.

!!! note "Dude, that's too complicated!"
    There's an easier way, with some limitations. If you configure MetalLB in L2 mode, all you need to do is to define a range of IPs within your existing node subnet, like this:

    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
    namespace: metallb-system
    name: metallb-config
    data:
      config: |
        address-pools:
        - name: default
        protocol: layer2
        addresses:
        - 192.168.1.240-192.168.1.250
    ```


### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy MetalLB into the cluster, with the config and extra ConfigMap we defined above. I save this in my flux repo as `metallb/helmrelease-metallb.yaml`:

??? example "Example HelmRelease (click to expand)"
    ```yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: metallb
      namespace: metallb-system
    spec:
      chart:
        spec:
          chart: metallb
          version: 2.x
          sourceRef:
            kind: HelmRepository
            name: bitnami
            namespace: flux-system
      interval: 15m
      timeout: 5m
      releaseName: metallb
      valuesFrom:
      - kind: ConfigMap
        name: metallb-helm-chart-value-overrides
        valuesKey: values.yaml # This is the default, but best to be explicit for clarity
    ```

!!! question "Why not just put config in the HelmRelease?"
    While it's true that we could embed values directly into the HelmRelease YAML, this becomes unweildy with large helm charts. It's also simpler (less likely to result in error) if changes to **HelmReleases**, which affect **deployment** of the chart, are defined in separate files to changes in helm chart **values**, which affect **operation** of the chart.

## Deploy MetalLB

Having committed the above to your flux repository, you should shortly see a metallb kustomization, and in the `metallb-system` namespace, a controller and a speaker pod for every node:

```bash
root@cn1:~# kubectl get pods -n metallb-system -o wide
NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE   NOMINATED NODE   READINESS GATES
metallb-controller-779d8686f6-mgb4s   1/1     Running   0          21d   10.0.6.19       wn3    <none>           <none>
metallb-speaker-2qh2d                 1/1     Running   0          21d   192.168.33.24   wn4    <none>           <none>
metallb-speaker-7rz24                 1/1     Running   0          21d   192.168.33.22   wn2    <none>           <none>
metallb-speaker-gbm5r                 1/1     Running   0          21d   192.168.33.23   wn3    <none>           <none>
metallb-speaker-gzgd2                 1/1     Running   0          21d   192.168.33.21   wn1    <none>           <none>
metallb-speaker-nz6kd                 1/1     Running   0          21d   192.168.33.25   wn5    <none>           <none>
root@cn1:~#
```

!!! question "Why are there no speakers on my masters?"

    In some cluster setups, master nodes are "tainted" to prevent workloads running on them and consuming capacity required for "mastering". If this is the case for you, but you actually **do** want to run some externally-exposed workloads on your masters, you'll need to update the `speaker.tolerations` value for the HelmRelease config to include:

    ```yaml
    - key: "node-role.kubernetes.io/master"
      effect: "NoSchedule"
    ```

### How do I know it's working?

If you used my [template repository](https://github.com/geek-cookbook/template-flux) to start off your [flux deployment strategy](/kubernetes/deployment/flux/), then the podinfo helm chart has already been deployed. By default, the podinfo service is in `ClusterIP` mode, so it's only reachable within the cluster.

Edit your podinfo helmrelease configmap (`/podinfo/configmap-podinfo-helm-chart-value-overrides.yaml`), and change this:

``` yaml hl_lines="6"
    <snip>
    # Kubernetes Service settings
    service:
      enabled: true
      annotations: {}
      type: ClusterIP
    <snip>
```

To:

``` yaml hl_lines="6"
    <snip>
    # Kubernetes Service settings
    service:
      enabled: true
      annotations: {}
      type: LoadBalancer
    <snip>
```

Commit your changes, wait for a reconciliation, and run `kubectl get services -n podinfo`. All going well, you should see that the service now has an IP assigned from the pool you chose for MetalLB!

--8<-- "recipe-footer.md"

[^1]: I've documented an example re [how to configure BGP between MetalLB and pfsense](/kubernetes/loadbalancer/metallb/pfsense/).