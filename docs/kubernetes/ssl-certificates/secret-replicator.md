# Secret Replicator

As explained when creating our [LetsEncrypt Wildcard certificates](/kubernetes/ssl-certificates/wildcard-certificate/), it can be problematic that Certificates can't be **shared** between namespaces. One simple solution to this problem is simply to "replicate" secrets from one "source" namespace into all other namespaces.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] [secret-replicator](/kubernetes/ssl-certificates/secret-replicator/) deployed to request/renew certificates
    * [x] [LetsEncrypt Wildcard Certificates](/kubernetes/ssl-certificates/wildcard-certificate/) created in the `letsencrypt-wildcard-cert` namespace

Kiwigrid's "[Secret Replicator](https://github.com/kiwigrid/secret-replicator)" is a simple controller which replicates secrets from one namespace to another.[^1]

## Preparation

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-secret-replicator.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: secret-replicator
```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/helmrepositories/helmrepository-kiwigrid.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: kiwigrid
  namespace: flux-system
spec:
  interval: 15m
  url: https://kiwigrid.github.io
```

### Kustomization

Now that the "global" elements of this deployment have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/secret-replicator`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-secret-replicator.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: secret-replicator
  namespace: flux-system
spec:
  interval: 15m
  path: ./secret-replicator
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  validation: server
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: secret-replicator
      namespace: secret-replicator
```

### ConfigMap

Now we're into the secret-replicator-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/kiwigrid/helm-charts/blob/master/charts/secret-replicator/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml  hl_lines="21 27" title="/secret-replicator/configmap-secret-replicator-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: secret-replicator-helm-chart-value-overrides
  namespace: secret-replicator
data:
  values.yaml: |-
    # Default values for secret-replicator.
    # This is a YAML-formatted file.
    # Declare variables to be passed into your templates.

    image:
    repository: kiwigrid/secret-replicator
    tag: 0.2.0
    pullPolicy: IfNotPresent
    ## Specify ImagePullSecrets for Pods
    ## ref: https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod
    # pullSecrets: myregistrykey

    # csv list of secrets
    secretList: "letsencrypt-wildcard-cert"
    # secretList: "secret1,secret2

    ignoreNamespaces: "kube-system,kube-public"

    # If defined, allow secret-replicator to watch for secrets in _another_ namespace
    secretNamespace: letsencrypt-wildcard-cert"

    rbac:
    enabled: true

    resources: {}
    # limits:
    #   cpu: 50m
    #   memory: 20Mi
    # requests:
    #   cpu: 20m
    #   memory: 20Mi

    nodeSelector: {}

    tolerations: []

    affinity: {}
```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Note that the following values changed from default, above:

- `secretList`: `letsencrypt-wildcard-cert`
- `secretNamespace`: `letsencrypt-wildcard-cert`

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy the secret-replicator controller into the cluster, with the config we defined above. I save this in my flux repo:

    ```yaml title="/secret-replicator/helmrelease-secret-replicator.yaml"
      apiVersion: helm.toolkit.fluxcd.io/v2beta1
      kind: HelmRelease
      metadata:
        name: secret-replicator
        namespace: secret-replicator
      spec:
        chart:
          spec:
            chart: secret-replicator
            version: 0.6.x
            sourceRef:
              kind: HelmRepository
              name: kiwigrid
              namespace: flux-system
        interval: 15m
        timeout: 5m
        releaseName: secret-replicator
        valuesFrom:
        - kind: ConfigMap
          name: secret-replicator-helm-chart-value-overrides
          valuesKey: values.yaml # This is the default, but best to be explicit for clarity
    ```

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Serving

Once you've committed your YAML files into your repo, you should soon see some pods appear in the `secret-replicator` namespace!

### How do we know it worked?

Look for secrets across the whole cluster, by running `kubectl get secrets -A | grep letsencrypt-wildcard-cert`. What you should see is an identical secret in every namespace. Note that the **Certificate** only exists in the `letsencrypt-wildcard-cert` namespace, but the secret it **generates** is what gets replicated to every other namespace.

### Troubleshooting

If your certificate is not created **aren't** created as you expect, then the best approach is to check the secret-replicator logs, by running `kubectl logs -n secret-replicator -l app.kubernetes.io/name=secret-replicator`.

--8<-- "recipe-footer.md"

[^1]: To my great New Zealandy confusion, "Kiwigrid GmbH" is a German company :shrug:
