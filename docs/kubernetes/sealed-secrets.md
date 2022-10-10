---
description: Securely store your secrets in plain sight
---

# Sealed Secrets

So you're sold on GitOps, you're using the [flux deployment strategy](/kubernetes/deployment/flux/) to deploy all your applications into your cluster, and you sleep like a baby 🍼 at night, knowing that you could rebuild your cluster with a few commands, given every change is stored in git's history.

But what about your secrets?

In Kubernetes, a "Secret" is a "teeny-weeny" bit more secure ConfigMap, in that it's base-64 encoded to prevent shoulder-surfing, and access to secrets can be restricted (*separately to ConfigMaps*) using Kubernetes RBAC. In some cases, applications deployed via helm expect to find existing secrets within the cluster, containing things like AWS credentials (*External DNS, Cert Manager*), admin passwords (*Grafana*), etc.

They're still not very secret though, and you certainly wouldn't want to be storing base64-encoded secrets in a git repository, public or otherwise!

An elegant solution to this problem is Bitnami Labs' Sealed Secrets.

![Sealed Secrets illustration](/images/sealed-secrets.png){ loading=lazy }

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

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-sealed-secrets.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: sealed-secrets
```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `bootstrap/helmrepositories/helmrepository-sealedsecrets.yaml`:

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

Now that the "global" elements of this deployment (*just the HelmRepository in this case*z*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/sealed-secrets`. I create this example Kustomization in my flux repo at `bootstrap/kustomizations/kustomization-sealed-secrets.yaml`:

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

{% raw %}
Now we're into the sealed-secrets-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/bitnami-labs/sealed-secrets/blob/main/helm/sealed-secrets/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo at `sealed-secrets/configmap-sealed-secrets-helm-chart-value-overrides.yaml`:

??? example "Example ConfigMap (click to expand)"
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      creationTimestamp: null
      name: sealed-secrets-helm-chart-value-overrides
      namespace: sealed-secrets
    data:
      values.yaml: |-
        ## @section Common parameters

        ## @param kubeVersion Override Kubernetes version
        ##
        kubeVersion: ""
        ## @param nameOverride String to partially override sealed-secrets.fullname
        ##
        nameOverride: ""
        ## @param fullnameOverride String to fully override sealed-secrets.fullname
        ##
        fullnameOverride: ""
        ## @param namespace Namespace where to deploy the Sealed Secrets controller
        ##
        namespace: ""
        ## @param extraDeploy [array] Array of extra objects to deploy with the release
        ##
        extraDeploy: []

        ## @section Sealed Secrets Parameters

        ## Sealed Secrets image
        ## ref: https://quay.io/repository/bitnami/sealed-secrets-controller?tab=tags
        ## @param image.registry Sealed Secrets image registry
        ## @param image.repository Sealed Secrets image repository
        ## @param image.tag Sealed Secrets image tag (immutable tags are recommended)
        ## @param image.pullPolicy Sealed Secrets image pull policy
        ## @param image.pullSecrets [array]  Sealed Secrets image pull secrets
        ##
        image:
          registry: quay.io
          repository: bitnami/sealed-secrets-controller
          tag: v0.17.2
          ## Specify a imagePullPolicy
          ## Defaults to 'Always' if image tag is 'latest', else set to 'IfNotPresent'
          ## ref: http://kubernetes.io/docs/user-guide/images/#pre-pulling-images
          ##
          pullPolicy: IfNotPresent
          ## Optionally specify an array of imagePullSecrets.
          ## Secrets must be manually created in the namespace.
          ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
          ## e.g:
          ## pullSecrets:
          ##   - myRegistryKeySecretName
          ##
          pullSecrets: []
        ## @param createController Specifies whether the Sealed Secrets controller should be created
        ##
        createController: true
        ## @param secretName The name of an existing TLS secret containing the key used to encrypt secrets
        ##
        secretName: "sealed-secrets-key"
        ## Sealed Secret resource requests and limits
        ## ref: http://kubernetes.io/docs/user-guide/compute-resources/
        ## @param resources.limits [object] The resources limits for the Sealed Secret containers
        ## @param resources.requests [object] The requested resources for the Sealed Secret containers
        ##
        resources:
          limits: {}
          requests: {}
        ## Configure Pods Security Context
        ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod
        ## @param podSecurityContext.enabled Enabled Sealed Secret pods' Security Context
        ## @param podSecurityContext.fsGroup Set Sealed Secret pod's Security Context fsGroup
        ##
        podSecurityContext:
          enabled: true
          fsGroup: 65534
        ## Configure Container Security Context
        ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod
        ## @param containerSecurityContext.enabled Enabled Sealed Secret containers' Security Context
        ## @param containerSecurityContext.readOnlyRootFilesystem Whether the Sealed Secret container has a read-only root filesystem
        ## @param containerSecurityContext.runAsNonRoot Indicates that the Sealed Secret container must run as a non-root user
        ## @param containerSecurityContext.runAsUser Set Sealed Secret containers' Security Context runAsUser
        ##
        containerSecurityContext:
          enabled: true
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1001
        ## @param podLabels [object] Extra labels for Sealed Secret pods
        ## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
        ##
        podLabels: {}
        ## @param podAnnotations [object] Annotations for Sealed Secret pods
        ## ref: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/
        ##
        podAnnotations: {}
        ## @param priorityClassName Sealed Secret pods' priorityClassName
        ##
        priorityClassName: ""
        ## @param affinity [object] Affinity for Sealed Secret pods assignment
        ## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
        ##
        affinity: {}
        ## @param nodeSelector [object] Node labels for Sealed Secret pods assignment
        ## ref: https://kubernetes.io/docs/user-guide/node-selection/
        ##
        nodeSelector: {}
        ## @param tolerations [array] Tolerations for Sealed Secret pods assignment
        ## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
        ##
        tolerations: []

        ## @param updateStatus Specifies whether the Sealed Secrets controller should update the status subresource
        ##
        updateStatus: true

        ## @section Traffic Exposure Parameters

        ## Sealed Secret service parameters
        ##
        service:
          ## @param service.type Sealed Secret service type
          ##
          type: ClusterIP
          ## @param service.port Sealed Secret service HTTP port
          ##
          port: 8080
          ## @param service.nodePort Node port for HTTP
          ## Specify the nodePort value for the LoadBalancer and NodePort service types
          ## ref: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
          ## NOTE: choose port between <30000-32767>
          ##
          nodePort: ""
          ## @param service.annotations [object] Additional custom annotations for Sealed Secret service
          ##
          annotations: {}
        ## Sealed Secret ingress parameters
        ## ref: http://kubernetes.io/docs/user-guide/ingress/
        ##
        ingress:
          ## @param ingress.enabled Enable ingress record generation for Sealed Secret
          ##
          enabled: false
          ## @param ingress.pathType Ingress path type
          ##
          pathType: ImplementationSpecific
          ## @param ingress.apiVersion Force Ingress API version (automatically detected if not set)
          ##
          apiVersion: ""
          ## @param ingress.ingressClassName IngressClass that will be be used to implement the Ingress
          ## This is supported in Kubernetes 1.18+ and required if you have more than one IngressClass marked as the default for your cluster.
          ## ref: https://kubernetes.io/blog/2020/04/02/improvements-to-the-ingress-api-in-kubernetes-1.18/
          ##
          ingressClassName: ""
          ## @param ingress.hostname Default host for the ingress record
          ##
          hostname: sealed-secrets.local
          ## @param ingress.path Default path for the ingress record
          ##
          path: /v1/cert.pem
          ## @param ingress.annotations [object] Additional annotations for the Ingress resource. To enable certificate autogeneration, place here your cert-manager annotations.
          ## Use this parameter to set the required annotations for cert-manager, see
          ## ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
          ## e.g:
          ## annotations:
          ##   kubernetes.io/ingress.class: nginx
          ##   cert-manager.io/cluster-issuer: cluster-issuer-name
          ##
          annotations:
          ## @param ingress.tls Enable TLS configuration for the host defined at `ingress.hostname` parameter
          ## TLS certificates will be retrieved from a TLS secret with name: `{{- printf "%s-tls" .Values.ingress.hostname }}`
          ## You can:
          ##   - Use the `ingress.secrets` parameter to create this TLS secret
          ##   - Relay on cert-manager to create it by setting the corresponding annotations
          ##   - Relay on Helm to create self-signed certificates by setting `ingress.selfSigned=true`
          ##
          tls: false
          ## @param ingress.selfSigned Create a TLS secret for this ingress record using self-signed certificates generated by Helm
          ##
          selfSigned: false
          ## @param ingress.extraHosts [array] An array with additional hostname(s) to be covered with the ingress record
          ## e.g:
          ## extraHosts:
          ##   - name: sealed-secrets.local
          ##     path: /
          ##
          extraHosts: []
          ## @param ingress.extraPaths [array] An array with additional arbitrary paths that may need to be added to the ingress under the main host
          ## e.g:
          ## extraPaths:
          ## - path: /*
          ##   backend:
          ##     serviceName: ssl-redirect
          ##     servicePort: use-annotation
          ##
          extraPaths: []
          ## @param ingress.extraTls [array] TLS configuration for additional hostname(s) to be covered with this ingress record
          ## ref: https://kubernetes.io/docs/concepts/services-networking/ingress/#tls
          ## e.g:
          ## extraTls:
          ## - hosts:
          ##     - sealed-secrets.local
          ##   secretName: sealed-secrets.local-tls
          ##
          extraTls: []
          ## @param ingress.secrets [array] Custom TLS certificates as secrets
          ## NOTE: 'key' and 'certificate' are expected in PEM format
          ## NOTE: 'name' should line up with a 'secretName' set further up
          ## If it is not set and you're using cert-manager, this is unneeded, as it will create a secret for you with valid certificates
          ## If it is not set and you're NOT using cert-manager either, self-signed certificates will be created valid for 365 days
          ## It is also possible to create and manage the certificates outside of this helm chart
          ## Please see README.md for more information
          ## e.g:
          ## secrets:
          ##   - name: sealed-secrets.local-tls
          ##     key: |-
          ##       -----BEGIN RSA PRIVATE KEY-----
          ##       ...
          ##       -----END RSA PRIVATE KEY-----
          ##     certificate: |-
          ##       -----BEGIN CERTIFICATE-----
          ##       ...
          ##       -----END CERTIFICATE-----
          ##
          secrets: []
        ## Network policies
        ## Ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/
        ##
        networkPolicy:
          ## @param networkPolicy.enabled Specifies whether a NetworkPolicy should be created
          ##
          enabled: false

        ## @section Other Parameters

        ## ServiceAccount configuration
        ##
        serviceAccount:
          ## @param serviceAccount.create Specifies whether a ServiceAccount should be created
          ##
          create: true
          ## @param serviceAccount.labels Extra labels to be added to the ServiceAccount
          ##
          labels: {}
          ## @param serviceAccount.name The name of the ServiceAccount to use.
          ## If not set and create is true, a name is generated using the sealed-secrets.fullname template
          ##
          name: ""
        ## RBAC configuration
        ##
        rbac:
          ## @param rbac.create Specifies whether RBAC resources should be created
          ##
          create: true
          ## @param rbac.labels Extra labels to be added to RBAC resources
          ##
          labels: {}
          ## @param rbac.pspEnabled PodSecurityPolicy
          ##
          pspEnabled: false

        ## @section Metrics parameters

        metrics:
          ## Prometheus Operator ServiceMonitor configuration
          ##
          serviceMonitor:
            ## @param metrics.serviceMonitor.enabled Specify if a ServiceMonitor will be deployed for Prometheus Operator
            ##
            enabled: false
            ## @param metrics.serviceMonitor.namespace Namespace where Prometheus Operator is running in
            ##
            namespace: ""
            ## @param metrics.serviceMonitor.labels Extra labels for the ServiceMonitor
            ##
            labels: {}
            ## @param metrics.serviceMonitor.annotations Extra annotations for the ServiceMonitor
            ##
            annotations: {}
            ## @param metrics.serviceMonitor.interval How frequently to scrape metrics
            ## e.g:
            ## interval: 10s
            ##
            interval: ""
            ## @param metrics.serviceMonitor.scrapeTimeout Timeout after which the scrape is ended
            ## e.g:
            ## scrapeTimeout: 10s
            ##
            scrapeTimeout: ""
            ## @param metrics.serviceMonitor.metricRelabelings [array] Specify additional relabeling of metrics
            ##
            metricRelabelings: []
            ## @param metrics.serviceMonitor.relabelings [array] Specify general relabeling
            ##
            relabelings: []
          ## Grafana dashboards configuration
          ##
          dashboards:
            ## @param metrics.dashboards.create Specifies whether a ConfigMap with a Grafana dashboard configuration should be created
            ## ref https://github.com/helm/charts/tree/master/stable/grafana#configuration
            ##
            create: false
            ## @param metrics.dashboards.labels Extra labels to be added to the Grafana dashboard ConfigMap
            ##
            labels: {}
            ## @param metrics.dashboards.namespace Namespace where Grafana dashboard ConfigMap is deployed
            ##
            namespace: ""


    ```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration (*I stick with the defaults*).

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy the sealed-secrets controller into the cluster, with the config we defined above. I save this in my flux repo:

```yaml title="/sealed-secrets/helmrelease-sealed-secrets.yaml"
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
{% endraw %}

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
