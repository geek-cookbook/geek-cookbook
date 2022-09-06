# External DNS

Kubernetes' internal DNS / service-discovery means that every service is resolvable within the cluster. You can create a Wordpress pod with a database URL pointing to "mysql", and trust that it'll find the service named "mysql" in the same namespace. (*Or "mysql.weirdothernamespace" if you prefer*)

This super-handy DNS magic only works within the cluster though. When you wanted to connect to the hypothetical Wordpress service from **outside** of the cluster, you'd need to manually create a DNS entry pointing to the [LoadBalancer](/kubernetes/loadbalancer/) IP of that service. While using wildcard DNS might make this a **little** easier, it's still too manual and not at all "*gitopsy*" enough!

ExternalDNS is a controller for Kubernetes which watches the objects you create (*Services, Ingresses, etc*), and configures External DNS providers (*like CloudFlare, Route53, etc*) accordingly. With External DNS, you **can** just deploy an ingress referencing "*mywordywordpressblog.batman.com*", and have that DNS entry autocreated on your provider within minutes 💪

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] API credentials for a [supported DNS provider](https://github.com/kubernetes-sigs/external-dns)

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-external-dns.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns
```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. In this case, we're using the (*prolific*) [bitnami chart repository](https://github.com/bitnami/charts/tree/master/bitnami), so per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/helmrepositories/helmrepository-bitnami.yaml"
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

Now that the "global" elements of this deployment (*just the HelmRepository in this case*z*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/external-dns`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-external-dns.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: external-dns
  namespace: flux-system
spec:
  interval: 15m
  path: ./external-dns
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  validation: server
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: external-dns
      namespace: external-dns
```

### ConfigMap

Now we're into the external-dns-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/bitnami/charts/blob/master/bitnami/external-dns/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="/external-dns/configmap-external-dns-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: traefik-helm-chart-value-overrides
  namespace: traefik
data:
  values.yaml: |-
    # <upstream values go here>
```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration.

I recommend changing:

```yaml
        sources:
          # - crd
          - service
          - ingress
          # - contour-httpproxy
```

To:

```yaml
        sources:
          - crd
          # - service
          # - ingress
          # - contour-httpproxy
```

!!! question "Why only use CRDs as a source?"
    > I thought the whole point of this magic was to create DNS entries from services or ingresses!

    You can do that, yes. However, I prefer to be prescriptive, and explicitly decide when a DNS entry will be created. By [using CRDs](#using-crds) (*External DNS creates a new type of resource called a "DNSEndpoint"*), I add my DNS entries as YAML files into each kustomization, and I can still employ wildcard DNS where appropriate.

### Secret

As you work your way through `values.yaml`, you'll notice that it contains specific placholders for credentials for various DNS providers.
Take for example, this config for cloudflare:

```yaml title="Example snippet of CloudFlare config from ConfigMap"
        cloudflare:
          ## @param cloudflare.apiToken When using the Cloudflare provider, `CF_API_TOKEN` to set (optional)
          ##
          apiToken: ""
          ## @param cloudflare.apiKey When using the Cloudflare provider, `CF_API_KEY` to set (optional)
          ##
          apiKey: ""
          ## @param cloudflare.secretName When using the Cloudflare provider, it's the name of the secret containing cloudflare_api_token or cloudflare_api_key.
          ## This ignores cloudflare.apiToken, and cloudflare.apiKey
          ##
          secretName: ""
          ## @param cloudflare.email When using the Cloudflare provider, `CF_API_EMAIL` to set (optional). Needed when using CF_API_KEY
          ##
          email: ""
          ## @param cloudflare.proxied When using the Cloudflare provider, enable the proxy feature (DDOS protection, CDN...) (optional)
          ##
          proxied: true
```

In the case of CloudFlare (*and this may differ per-provider*), you can either enter your credentials in cleartext (*baaad idea, since we intend to commit these files into a repo*), or you can reference a secret, which External DNS will expect to find in its namespace.

Thanks to [Sealed Secrets](/kubernetes/sealed-secrets/), we have a safe way of committing secrets into our repository, so to create this cloudflare secret, you'd run something like this:

```bash
  kubectl create secret generic cloudflare-api-token \
  --namespace external-dns \
  --dry-run=client \
  --from-literal=cloudflare_api_token=gobbledegook -o json \
  | kubeseal --cert <path to public cert> \
  | kubectl create -f - \
  > <path to repo>/external-dns/sealedsecret-cloudflare-api-token.yaml
```

And your sealed secret would end up in `external-dns/sealedsecret-cloudflare-api-token.yaml`.

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy the external-dns controller into the cluster, with the config we defined above. I save this in my flux repo as:

```yaml title="/external-dns/helmrelease-external-dns.yaml"
  apiVersion: helm.toolkit.fluxcd.io/v2beta1
  kind: HelmRelease
  metadata:
    name: external-dns
    namespace: external-dns
  spec:
    chart:
      spec:
        chart: external-dns
        version: 4.x
        sourceRef:
          kind: HelmRepository
          name: bitnami
          namespace: flux-system
    interval: 15m
    timeout: 5m
    releaseName: external-dns
    valuesFrom:
    - kind: ConfigMap
      name: external-dns-helm-chart-value-overrides
      valuesKey: values.yaml # This is the default, but best to be explicit for clarity
```

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Serving

Once you've committed your YAML files into your repo, you should soon see some pods appear in the `external-dns` namespace!

### Using CRDs

If you're the sort of person who doesn't like to just leak[^1] every service/ingress name into public DNS, you may prefer to manage your DNS entries using CRDs.

You can instruct ExternalDNS to create any DNS entry you please, using a **DNSEndpoint** resource, and place these in the appropriate folder in your flux repo to be deployed with your HelmRelease:

```yaml
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: batcave.example.com
  namespace: batcave
spec:
  endpoints:
  - dnsName: batcave.example.com
    recordTTL: 180
    recordType: A
    targets:
    - 192.168.99.216
```

You can even create wildcard DNS entries, for example by setting `dnsName: *.batcave.example.com`.

Finally, (*and this is how I prefer to manage mine*), you can create a few A records for "permanent" endpoints stuff like Ingresses, and then point arbitrary DNS names to these records, like this:

```yaml
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: "robinsroost.example.com"
  namespace: batcave
spec:
  endpoints:
  - dnsName: "robinsroost.example.com"
    recordTTL: 180
    recordType: CNAME
    targets:
    - "batcave.example.com"
```

### Troubleshooting

If DNS entries **aren't** created as you expect, then the best approach is to check the external-dns logs, by running `kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns`.

--8<-- "recipe-footer.md"

[^1]: Why yes, I **have** accidentally caused outages / conflicts by "leaking" DNS entries automatically!
