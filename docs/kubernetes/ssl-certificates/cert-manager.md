---
title: Install cert-manager in Kubernetes
description: Cert Manager generates and renews LetsEncrypt certificates
---
# Cert Manager

To interact with your cluster externally, you'll almost certainly be using a web browser, and you'll almost certainly be wanting your browsing session to be SSL-secured. Some Ingress Controllers (i.e. Traefik) will include a default, self-signed, nasty old cert which will permit you to use SSL, but it's faaaar better to use valid certs.

Cert Manager adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the process of obtaining, renewing and using those certificates.

![Cert Manager illustration](/images/cert-manager.svg)

It can issue certificates from a variety of supported sources, including Let’s Encrypt, HashiCorp Vault, and Venafi as well as private PKI.

It will ensure certificates are valid and up to date, and attempt to renew certificates at a configured time before expiry.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-cert-manager.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager
```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/helmrepositories/helmrepository-jetstack.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: jetstack
  namespace: flux-system
spec:
  interval: 15m
  url: https://charts.jetstack.io
```

### Kustomization

Now that the "global" elements of this deployment (*just the HelmRepository in this case*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/cert-manager`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-cert-manager.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: cert-manager
  namespace: flux-system
spec:
  interval: 15m
  path: ./cert-manager
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: cert-manager
      namespace: cert-manager
```

### ConfigMap

Now we're into the cert-manager-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 tabs (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo at `cert-manager/configmap-cert-manager-helm-chart-value-overrides.yaml`:

```yaml title="/cert-manager/configmap-cert-manager-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: cert-manager-helm-chart-value-overrides
  namespace: cert-manager
data:
  values.yaml: |-
    # paste chart values.yaml (indented) here and alter as required>
```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration.

!!! tip "set installCRDs to true"
    An upstream value of particular note is `installCRDs` - set this to `true`, unless you plan to deploy the cert-manager CRDs another way.

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy the cert-manager controller into the cluster, with the config we defined above. I save this in my flux repo:

```yaml title="/cert-manager/helmrelease-cert-manager.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  chart:
    spec:
      chart: cert-manager
      version: v1.15.x
      sourceRef:
        kind: HelmRepository
        name: jetstack
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: cert-manager
  valuesFrom:
  - kind: ConfigMap
    name: cert-manager-helm-chart-value-overrides
    valuesKey: values.yaml # This is the default, but best to be explicit for clarity
```

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Serving

Once you've committed your YAML files into your repo, you should soon see some pods appear in the `cert-manager` namespace!

What do we have now? Well, we've got the cert-manager controller **running**, but it won't **do** anything until we define some certificate issuers, credentials, and certificates..

### Troubleshooting

If your certificate is not created **aren't** created as you expect, then the best approach is to check the cert-manager logs, by running `kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager`.

{% include 'recipe-footer.md' %}

[^1]: Why yes, I **have** accidentally rate-limited myself by deleting/recreating my prod certificates a few times!
