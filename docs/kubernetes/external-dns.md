---
title: Support CSI VolumeSnapshots with snapshot-controller
description: Add CSI VolumeSnapshot support with snapshot support
values_yaml_url: https://github.com/bitnami/charts/blob/master/bitnami/external-dns/values.yaml
helm_chart_version: 5.1.x
helm_chart_name: external-dns
helm_chart_repo_name: bitnami
helm_chart_repo_url: https://charts.bitnami.com/bitnami
helmrelease_name: external-dns
helmrelease_namespace: external-dns
kustomization_name: external-dns
slug: External DNS
---

# External DNS

Kubernetes' internal DNS / service-discovery means that every service is resolvable within the cluster. You can create a Wordpress pod with a database URL pointing to "mysql", and trust that it'll find the service named "mysql" in the same namespace. (*Or "mysql.weirdothernamespace" if you prefer*)

This super-handy DNS magic only works within the cluster though. When you wanted to connect to the hypothetical Wordpress service from **outside** of the cluster, you'd need to manually create a DNS entry pointing to the [LoadBalancer](/kubernetes/loadbalancer/) IP of that service. While using wildcard DNS might make this a **little** easier, it's still too manual and not at all "*gitopsy*" enough!

ExternalDNS is a controller for Kubernetes which watches the objects you create (*Services, Ingresses, etc*), and configures External DNS providers (*like CloudFlare, Route53, etc*) accordingly. With External DNS, you **can** just deploy an ingress referencing "*mywordywordpressblog.batman.com*", and have that DNS entry autocreated on your provider within minutes 💪

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] API credentials for a [supported DNS provider](https://github.com/kubernetes-sigs/external-dns)

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

#### Configure External DNS

I recommend changing at least:

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

As you work your way through `values.yaml`, you'll notice that it contains specific placeholders for credentials for various DNS providers.

Take for example, this config for cloudflare:

```yaml title="Example snippet of CloudFlare config from upstream values.yaml"
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
  > <path to repo>/external-dns/sealedsecret-cloudflare-api-token.yaml
```

And your sealed secret would end up in `external-dns/sealedsecret-cloudflare-api-token.yaml`.

{% include 'kubernetes-flux-check.md' %}

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

## Summary

What have we achieved? By simply creating another YAML in our flux repo alongside our app HelmReleases, we can record and create the necessary DNS entries, without fiddly manual intervetion!

!!! summary "Summary"
    Created:

    * [X] DNS records are created automatically based on YAMLs (*or even just on services and ingresses!*)

--8<-- "recipe-footer.md"

[^1]: Why yes, I **have** accidentally caused outages / conflicts by "leaking" DNS entries automatically!
