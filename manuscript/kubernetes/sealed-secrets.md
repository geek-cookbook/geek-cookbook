---
description: Securely store your secrets in plain sight
---

# Sealed Secrets

So you're sold on GitOps, you're using the [flux deployment strategy](/kubernetes/deployment/flux/) to deploy all your applications into your cluster, and you sleep like a baby 🍼 at night, knowing that you could rebuild your cluster with a few commands, given every change is stored in git's history.

But what about your secrets?

In Kubernetes, a "Secret" is a "teeny-weeny" bit more secure ConfigMap, in that it's base-64 encoded to prevent shoulder-surfing, and access to secrets can be restricted (*separately to ConfigMaps*) using Kubernetes RBAC. In some cases, applications deployed via helm expect to find existing secrets within the cluster, containing things like AWS credentials (*External DNS, Cert Manager*), admin passwords (*Grafana*), etc.

They're still not very secret though, and you certainly wouldn't want to be storing base64-encoded secrets in a git repository, public or otherwise!

An elegant solution to this problem is Bitnami Labs' Sealed Secrets.

![Sealed Secrets illustration](../../images/sealed-secrets.png)

A "[SealedSecret](https://github.com/bitnami-labs/sealed-secrets)" can only be decrypted (*and turned back into a regular Secret*) by the controller in the target cluster. (*or by a controller in another cluster which has been primed with your own private/public pair)* This means the SealedSecret is safe to store and expose anywhere.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

    Optional:

    * [ ] Your own private/public PEM certificate pair for secret encryption/decryption (*ideal but not required*)

## Preparation

### Install kubeseal CLI

=== "HomeBrew (MacOS/Linux)"

    With [Homebrew](https://brew.sh/) for macOS and Linux:
    
    ```bash
    brew install kubeseal
    ```

=== "Bash (Linux)"

    With Bash for macOS and Linux:

    (Update for whatever the [latest release](https://github.com/bitnami-labs/sealed-secrets/releases) is)

    ```bash
    wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.17.0/kubeseal-linux-amd64 -O kubeseal
    sudo install -m 755 kubeseal /usr/local/bin/kubeseal
    ```

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this in my flux repo at `flux-system/namespaces/namespace-sealed-secrets.yaml`:

??? example "Example Namespace (click to expand)"
    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: sealed-secrets
    ```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. Per the [flux design](/kubernetes/deployment/flux/), I create this in my flux repo at `flux-system/helmrepositories/helmrepository-sealedsecrets.yaml`:

??? example "Example HelmRepository (click to expand)"
    ```yaml
    apiVersion: source.toolkit.fluxcd.io/v1beta1
    kind: HelmRepository
    metadata:
      name: sealed-secrets
      namespace: flux-system
    spec:
      interval: 15m
      url: https://bitnami-labs.github.io/sealed-secrets
    ```

### Kustomization

Now that the "global" elements of this deployment (*just the HelmRepository in this case*z*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/sealed-secrets`. I create this Kustomization in my flux repo at `flux-system/kustomizations/kustomization-sealed-secrets.yaml`:

??? example "Example Kustomization (click to expand)"
    ```yaml
    apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
    kind: Kustomization
    metadata:
      name: sealed-secrets
      namespace: flux-system
    spec:
      interval: 15m
      path: ./sealed-secrets
      prune: true # remove any elements later removed from the above path
      timeout: 2m # if not set, this defaults to interval duration, which is 1h
      sourceRef:
        kind: GitRepository
        name: flux-system
      validation: server
      healthChecks:
        - apiVersion: apps/v1
          kind: Deployment
          name: sealed-secrets
          namespace: sealed-secrets
    ```

### ConfigMap

Now we're into the sealed-secrets-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/bitnami-labs/sealed-secrets/blob/main/helm/sealed-secrets/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 tabs (*since they're "encapsulated" within the ConfigMap YAML*). I create this in my flux repo at `sealed-secrets/configmap-sealed-secrets-helm-chart-value-overrides.yaml`:

??? example "Example ConfigMap (click to expand)"
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
    creationTimestamp: null
    name: sealed-secrets-helm-chart-value-overrides
    namespace: sealed-secrets
    values.yaml: |-
        image:
        repository: quay.io/bitnami/sealed-secrets-controller
        tag: v0.17.0
        pullPolicy: IfNotPresent
        pullSecret: ""

        resources: {}
        nodeSelector: {}
        tolerations: []
        affinity: {}

        controller:
        # controller.create: `true` if Sealed Secrets controller should be created
        create: true
        # controller.labels: Extra labels to be added to controller deployment
        labels: {}
        # controller.service: Configuration options for controller service
        service:
            # controller.service.labels: Extra labels to be added to controller service
            labels: {}

        # namespace: Namespace to deploy the controller.
        namespace: ""

        serviceAccount:
        # serviceAccount.create: Whether to create a service account or not
        create: true
        # serviceAccount.labels: Extra labels to be added to service account
        labels: {}
        # serviceAccount.name: The name of the service account to create or use
        name: ""

        rbac:
        # rbac.create: `true` if rbac resources should be created
        create: true
        # rbac.labels: Extra labels to be added to rbac resources
        labels: {}
        pspEnabled: false

        # secretName: The name of the TLS secret containing the key used to encrypt secrets
        secretName: "sealed-secrets-key"

        ingress:
        enabled: false
        annotations: {}
            # kubernetes.io/ingress.class: nginx
            # kubernetes.io/tls-acme: "true"
        path: /v1/cert.pem
        hosts:
            - chart-example.local
        tls: []
        #  - secretName: chart-example-tls
        #    hosts:
        #      - chart-example.local

        crd:
        # crd.create: `true` if the crd resources should be created
        create: true
        # crd.keep: `true` if the sealed secret CRD should be kept when the chart is deleted
        keep: true

        networkPolicy: false

        securityContext:
        # securityContext.runAsUser defines under which user the operator Pod and its containers/processes run.
        runAsUser: 1001
        # securityContext.fsGroup defines the filesystem group
        fsGroup: 65534

        podAnnotations: {}

        podLabels: {}

        priorityClassName: ""

        serviceMonitor:
        # Enables ServiceMonitor creation for the Prometheus Operator
        create: false
        # How frequently Prometheus should scrape the ServiceMonitor
        interval:
        # Extra labels to apply to the sealed-secrets ServiceMonitor
        labels:
        # The namespace where the ServiceMonitor is deployed, defaults to the installation namespace
        namespace:
        # The timeout after which the scrape is ended
        scrapeTimeout:

        dashboards:
        # If enabled, sealed-secrets will create a configmap with a dashboard in json that's going to be picked up by grafana
        # See https://github.com/helm/charts/tree/master/stable/grafana#configuration - `sidecar.dashboards.enabled`
        create: false
        # Extra labels to apply to the dashboard configmaps
        labels:
        # The namespace where the dashboards are deployed, defaults to the installation namespace
        namespace:

    ```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration (*I stick with the defaults*).

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy the sealed-secrets controller into the cluster, with the config we defined above. I save this in my flux repo as `sealed-secrets/helmrelease-sealed-secrets.yaml`:

??? example "Example HelmRelease (click to expand)"
    ```yaml
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: sealed-secrets
      namespace: sealed-secrets
    spec:
      chart:
        spec:
          chart: sealed-secrets
          version: 1.x
          sourceRef:
            kind: HelmRepository
            name: sealed-secrets
            namespace: flux-system
      interval: 15m
      timeout: 5m
      releaseName: sealed-secrets
      valuesFrom:
      - kind: ConfigMap
        name: sealed-secrets-helm-chart-value-overrides
        valuesKey: values.yaml # This is the default, but best to be explicit for clarity
    ```

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Serving

Commit your files to your flux repo, and wait until you see pods show up in the `sealed-secrets` namespace.

Now you're ready to seal some secrets!

### Sealing a secret

To generate sealed secrets, we need the public key that the controller has generated. On a host with a valid `KUBECONFIG` env var, pointing to a kubeconfig file with cluster-admin privileges, run the following to retrieve the public key for the sealed secrets (*this is the public key, it doesn't need to be specifically protected*)

```bash
kubeseal --fetch-cert \
--controller-name=sealed-secrets \
--controller-namespace=sealed-secrets \
> pub-cert.pem
```

Now generate a kubernetes secret locally, using `kubectl --dry-run=client`, as illustrated below:

```bash
echo -n batman | kubectl create secret \
  generic mysecret --dry-run=client --from-file=foo=/dev/stdin -o json
```

The result should look like this:

```yaml
{
    "kind": "Secret",
    "apiVersion": "v1",
    "metadata": {
        "name": "mysecret",
        "creationTimestamp": null
    },
    "data": {
        "foo": "YmF0bWFu"
    }
}
```

Note that "*YmF0bWFu*", [base64 decoded](https://www.base64decode.org/), will reveal the top-secret secret. Not so secret, Batman!

Next, pipe the secret (*in json format*) to kubeseal, referencing the public key, and you'll get a totally un-decryptable "sealed" secret in return:

```bash
  echo -n batman | kubectl create secret \
  generic mysecret --dry-run=client --from-file=foo=/dev/stdin -o json \
  | kubeseal --cert pub-cert.pem
```

Resulting in something like this:

```json
{
  "kind": "SealedSecret",
  "apiVersion": "bitnami.com/v1alpha1",
  "metadata": {
    "name": "mysecret",
    "namespace": "default",
    "creationTimestamp": null
  },
  "spec": {
    "template": {
      "metadata": {
        "name": "mysecret",
        "namespace": "default",
        "creationTimestamp": null
      },
      "data": null
    },
    "encryptedData": {
      "foo": "AgAywfMzHx/4QFa3sa68zUbpmejT/MjuHUnfI/p2eo5xFKf2SsdGiRK4q2gl2yaSeEcAlA/P1vKZpsM+Jlh5WqrFxTtJjTYgXilzTSSTkK8hilZMflCnL1xs7ywH/lk+4gHdI7z0QS7FQztc649Z+SP2gjunOmTnRTczyCbzYlYSdHS9bB7xqLvGIofvn4dtQvapiTIlaFKhr+sDNtd8WVVzJ1eLuGgc9g6u1UjhuGa8NhgQnzXBd4zQ7678pKEpkXpUmINEKMzPchp9+ME5tIDASfV/R8rxkKvwN3RO3vbCNyLXw7KXRdyhd276kfHP4p4s9nUWDHthefsh19C6lT0ixup3PiG6gT8eFPa0v4jenxqtKNczmTwN9+dF4ZqHh93cIRvffZ7RS9IUOc9kUObQgvp3fZlo2B4m36G7or30ZfuontBh4h5INQCH8j/U3tXegGwaShGmKWg+kRFYQYC4ZqHCbNQJtvTHWKELQTStoAiyHyM+T36K6nCoJTixGZ/Nq4NzIvVfcp7I8LGzEbRSTdaO+MlTT3d32HjsJplXZwSzygSNrRRGwHKr5wfo5rTTdBVuZ0A1u1a6aQPQiJYSluKZwAIJKGQyfZC5Fbo+NxSxKS8MoaZjQh5VUPB+Q92WoPJoWbqZqlU2JZOuoyDWz5x7ZS812x1etQCy6QmuLYe+3nXOuQx85drJFdNw4KXzoQs2uSA="
    }
  }
}
```

!!! question "Who set the namespace to default?"
    By default, sealed secrets can only be "unsealed" in the same namespace for which the original secret was created. In the example above, we didn't explicitly specity a namespace when creating our secret, so the default namespace was used.

Apply the sealed secret to the cluster...

```bash
  echo -n batman | kubectl create secret \
  generic mysecret --dry-run=client --from-file=foo=/dev/stdin -o json \
  | kubeseal --cert pub-cert.pem \
  | kubectl create -f -
```

And watch the sealed-secrets controller decrypt it, and turn it into a regular secrets, using `kubectl logs -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets`

```bash
2021/11/16 10:37:16 Event(v1.ObjectReference{Kind:"SealedSecret", Namespace:"default", Name:"mysecret", 
UID:"82ac8c4b-c167-400e-8768-51957364f6b9", APIVersion:"bitnami.com/v1alpha1", ResourceVersion:"147314", 
FieldPath:""}): type: 'Normal' reason: 'Unsealed' SealedSecret unsealed successfully
```

Finally, confirm that the secret now exists in the `default` namespace:

```yaml
root@shredder:/tmp# kubectl get secret mysecret -o yaml
apiVersion: v1
data:
  foo: YmF0bWFu
kind: Secret
metadata:
  creationTimestamp: "2021-11-16T10:37:16Z"
  name: mysecret
  namespace: default
  ownerReferences:
  - apiVersion: bitnami.com/v1alpha1
    controller: true
    kind: SealedSecret
    name: mysecret
    uid: 82ac8c4b-c167-400e-8768-51957364f6b9
  resourceVersion: "147315"
  uid: 6f6ba81c-c9a2-45bc-877c-7a8b50afde83
type: Opaque
root@shredder:/tmp#
```

So we now have a means to store an un-decryptable secret in our flux repo, and have only our cluster be able to convert that sealedsecret into a regular secret!

Based on our [flux deployment strategy](/kubernetes/deployment/flux/), we simply seal up any necessary secrets into the appropriate folder in the flux repository, and have them decrypted and unsealed into the running cluster. For example, if we needed a secret for metallb called "magic-password", containing a key "location-of-rabbit", we'd do this:

```bash
  kubectl create secret generic magic-password \
  --namespace metallb-system \
  --dry-run=client \
  --from-literal=location-of-rabbit=top-hat -o json \
  | kubeseal --cert pub-cert.pem \
  | kubectl create -f - \
  > <path to repo>/metallb/sealedsecret-magic-password.yaml
```

Once flux reconciled the above sealedsecret, the sealedsecrets controller in the cluster would confirm that it's able to decrypt the secret, and would create the corresponding regular secret.

### Using our own keypair

One flaw in the process above is that we rely on the sealedsecrets controller to generate its own public/private keypair. This means that the pair (*and therefore all the encrypted secrets*) are specific to this cluster (*and this instance of the sealedsecrets controller*) only.

To go "fully GitOps", we'd want to be able to rebuild our entire cluster "from scratch" using our flux repository. If the keypair is recreated when a new cluster is built, then the existing sealedsecrets would remain forever "sealed"..

The solution here is to [generate our own public/private keypair](https://github.com/bitnami-labs/sealed-secrets/blob/main/docs/bring-your-own-certificates.md), and to store the private key safely and securely outside of the flux repo[^1]. We'll only need the key once, when deploying a fresh instance of the sealedsecrets controller.

Once you've got the public/private key pair, create them as kubernetes secrets directly in the cluster, like this:

```bash
kubectl -n sealed-secrets create secret tls my-own-certs \
  --cert="<path to public key>" --key="<path to private key>"
```

And then "label" the secret you just created, so that the sealedsecrets controller knows that it's special:

```bash
kubectl -n sealed-secrets label secret my-own-certs \
  sealedsecrets.bitnami.com/sealed-secrets-key=active
```

Restart the sealedsecret controller deployment, to force it to detect the new secret:

```bash
root@shredder:~# kubectl rollout restart -n sealed-secrets deployment sealed-secrets
deployment.apps/sealed-secrets restarted
root@shredder:~#
```

And now when you create your seadsecrets, refer to the public key you just created using `--cert <path to cert>`. These secrets will be decryptable by **any** sealedsecrets controller bootstrapped with the same keypair (*above*).

--8<-- "recipe-footer.md"

[^1]: There's no harm in storing the **public** key in the repo though, which means it's easy to refer to when sealing secrets.
