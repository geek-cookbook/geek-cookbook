# Operation

Having described [how to install flux](/kubernetes/deployment/flux/install/), and [how our flux deployment design works](/kubernetes/deployment/flux/design/), let's finish by exploring how to **use** flux to deploy helm charts into a cluster!

## Deploy App

We'll need 5 files per-app, to deploy and manage our apps using flux. The example below will use the following highlighted files:

```hl_lines="4 6 8 10 11"
├── README.md
├── flux-system
│   ├── helmrepositories
│   │   └── helmrepository-traefik.yaml
│   ├── kustomizations
│   │   └── kustomization-traefik.yaml
│   └── namespaces
│       └── namespace-traefik.yaml
└── traefik
    ├── configmap-traefik-helm-chart-value-overrides.yaml
    └── helmrelease-traefik.yaml
```

???+ question "5 files! That seems overly complex!"
    > "Why not just stick all the YAML into one folder and let flux reconcile it all-at-once?"

    Several reasons:

    * We need to be able to deploy multiple copies of the same helm chart into different namespaces. Imagine if you wanted to deploy a "postgres" helm chart into a namespace for KeyCloak, plus another one for NextCloud. Putting each HelmRelease resource into its own namespace allows us to do this, while sourcing them all from a common HelmRepository
    * As your cluster grows in complexity, you end up with dependency issues, and sometimes you need one chart deployed first, in order to create CRDs which are depended upon by a second chart (*like Prometheus' ServiceMonitor*). Isolating apps to a kustomization-per-app means you can implement dependencies and health checks to allow a complex cluster design without chicken vs egg problems! 
    * I like to use the one-object-per-yaml-file approach. Kubernetes is complex enough without trying to define multiple objects in one file, or having confusingly-generic filenames such as `app.yaml`! 🤦‍♂️

### Identify target helm chart

Identify your target helm chart. Let's take Traefik as an example. Here's the [official chart](https://github.com/traefik/traefik-helm-chart), and here's the [values.yaml](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml) which describes the default values passed to the chart (*and the options the user has to make changes*).

### Create HelmRepository

The README instructs users to add the repo "traefik" with the URL `https://helm.traefik.io/traefik`, so 
create a suitable HelmRepository YAML in `flux-system/helmrepositories/helmrepository-traefik.yaml`. Here's [my example](https://github.com/geek-cookbook/template-flux/blob/main/flux-system/helmrepositories/helmrepository-traefik.yaml).

!!! question "Why such obtuse file names?"
    > Why not just call the HelmRepository YAML `traefik.yaml`? Why prefix the filename with the API object `helmrepository-`?

    We're splitting the various "bits" which define this app into multiple YAMLs, and we'll soon have multiple apps in our repo, each with their own set of "bits". It gets very confusing quickly, when comparing git commit diffs, if you're not explicitly clear on what file you're working on, or which changes you're reviewing. Plus, adding the API object name to the filename provides extra "metadata" to the file structure, and makes "fuzzy searching" for quick-opening of files in tools like VSCode more effective.

### Create Namespace

Create a namespace for the chart. Typically you'd name this the same as your chart name. Here's [my namespace-traefik.yaml](https://github.com/geek-cookbook/template-flux/blob/main/flux-system/namespaces/namespace-traefik.yaml).

??? example "Here's an example Namespace..."

    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: traefik
    ```

### Create Kustomization

Create a kustomization for the chart, pointing flux to a path in the repo where the chart-specific YAMLs will be found. Here's my [kustomization-traefik.yaml](https://github.com/geek-cookbook/template-flux/blob/main/flux-system/kustomizations/kustomization-traefik.yaml).

??? example "Here's an example Kustomization..."

    ```yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
    kind: Kustomization
    metadata:
      name: traefik
      namespace: flux-system
    spec:
      interval: 15m
      path: traefik
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

### Create HelmRelease

Now create a HelmRelease for the chart - the HelmRelease defines how the (generic) chart from the HelmRepository will be installed into our cluster. Here's my [traefik/helmrelease-traefik.yaml](https://github.com/geek-cookbook/template-flux/blob/main/traefik/helmrelease-traefik.yaml).

??? example "Here's an example HelmRelease..."

    ```yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: traefik
      namespace: traefik
    spec:
      chart:
        spec:
          chart: traefik # Must be the same as the upstream chart name
          version: 10.x # Pin to semver major versions to avoid breaking changes but still get bugfixes/updates
          sourceRef:
            kind: HelmRepository
            name: traefik # References the HelmRepository you created earlier
            namespace: flux-system # All HelmRepositories exist in the flux-system namespace
      interval: 15m
      timeout: 5m
      releaseName: traefik # _may_ be different from the upstream chart name, but could cause confusion
      valuesFrom:
      - kind: ConfigMap
        name: traefik-helm-chart-value-overrides # Align with the name of the ConfigMap containing all values
        valuesKey: values.yaml # This is the default, but best to be explicit for clarity
    ```

### Create ConfigMap

Finally, create a ConfigMap to be used to pass helm chart values to the chart. Note that it is **possible** to pass values directly in the HelmRelease, but.. it's messy. I find it easier to let the HelmRelease **describe** the release, and to let the configmap **configure** the release. It also makes tracking changes more straightforward.

As a second note, it's strictly only necessary to include in the ConfigMap the values you want to **change** from the chart's defaults. I find this to be too confusing as charts are continually updated by their developers, and it hides valuable context. So I place in my ConfigMaps the **entire** contents of the chart's `values.yaml` file, and then I explicitly overwrite the values I want to change.

It's too large to display nicely below, but here's my [traefik/configmap-traefik-helm-chart-value-overrides.yaml](https://github.com/geek-cookbook/template-flux/blob/main/traefik/configmap-traefik-helm-chart-value-overrides.yaml)

!!! tip "Yes, I am sticking to my super-obtuse file naming convention!"
    Doesn't it make it easier to understand, at a glance, exactly what this YAML file is intended to be?

### Commit the changes

Simply commit your changes, sit back, and wait for flux to do its 1-min update. If you like to watch the fun, you could run `watch -n1 flux get kustomizations` so that you'll see the reconciliation take place (*if you're quick*). You can also force flux to check the repo for changes manually, by running `flux reconcile source git flux-system`.

## Making changes

Let's say you decide that instead of 1 replica of the Traefik pod, you'd like 3 replicas. Edit your configmap, change the highlighted line from `replicas: 1` to `replicas: 3`:

``` yaml hl_lines="10"
    <snip>
    #
    # Configure the deployment
    #
    deployment:
      enabled: true
      # Can be either Deployment or DaemonSet
      kind: Deployment
      # Number of pods of the deployment (only applies when kind == Deployment)
      replicas: 1
    <snip>
```

Commit your changes, and once again do the waiting / impatient-reconciling jig. This time you'll have to wait up to 15 minutes though...

!!! question "Why 15 minutes?"
    > I thought we check the repo every minute?

    Yes, we check the entire GitHub repository for changes every 1 min, and changes to a kustomization are applied immediately. I.e., your traefik ConfigMap gets updated within a minute (roughly). But the interval value for the HelmRelease is set to 15 minutes, so you could be waiting for as long as 15 minutes for flux to re-reconcile your HelmRelease with the ConfigMap, and to apply any changes. I've found that setting the HelmRelease interval too low causes (a) lots of unnecessary resource usage on behalf of flux, and (b) less stability when you have a large number of HelmReleases, some of whom depend on each other.

    You can force a HelmRelease to reconcile, by running `flux reconcile helmrelease -n <namespace> <name of helmrelease>`

## Success!

We did it. The Holy Grail. We deployed an application into the cluster, without touching the cluster. Pinch yourself, and then prove it worked by running `flux get kustomizations`, or `kubectl get helmreleases -n traefik`.

--8<-- "recipe-footer.md"

[^1]: Got suggestions for improvements here? Shout out in the comments below!
