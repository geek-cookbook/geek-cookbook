# LetsEncrypt Issuers

Certificates are issued by certificate authorities. By far the most common issuer will be LetsEncrypt.

In order for Cert Manager to request/renew certificates, we have to tell it about our **Issuers**.

!!! note
    There's a minor distinction between an **Issuer** (*only issues certificates within one namespace*) and a **ClusterIssuer** (*issues certificates throughout the cluster*). Typically a **ClusterIssuer** will be suitable.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] [Cert-Manager](/kubernetes/ssl-certificates/cert-manager/) deployed to request/renew certificates
    * [x] API credentials for a [supported DNS01 provider](https://cert-manager.io/docs/configuration/acme/dns01/) for LetsEncrypt wildcard certs

## Preparation

### Namespace

We need a namespace to deploy our certificates into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-letsencrypt-wildcard-cert.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: letsencrypt-wildcard-cert
```

### Kustomization

Now we need a kustomization to tell Flux to install any YAMLs it finds in `/letsencrypt-wildcard-cert`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-letsencrypt-wildcard-cert.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: letsencrypt-wildcard-cert
  namespace: flux-system
spec:
  interval: 15m
  path: ./letsencrypt-wildcard-cert
  dependsOn:
  - name: "cert-manager"
  - name: "sealed-secrets"
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
```

!!! tip
    Importantly, note that we define a **dependsOn**, to tell Flux not to try to reconcile this kustomization before the cert-manager and sealedsecrets kustomizations are reconciled. Cert-manager creates the CRDs used to define certificates, so prior to Cert Manager being installed, the cluster won't know what to do with the ClusterIssuers/Certificate resources.

### LetsEncrypt Staging

The ClusterIssuer resource below represents a certificate authority which is able to request certificates for any namespace within the cluster.
I save this in my flux repo as illustrated below. I've highlighted the areas you'll need to pay attention to:

```yaml hl_lines="8 15 17-21" title="/letsencrypt-wildcard-cert/cluster-issuer-letsencrypt-staging.yaml"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: batman@example.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - selector:
        dnsZones:
          - "example.com"
      dns01:
        cloudflare:
          email: batman@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
```

Deploying this issuer YAML into the cluster would provide Cert Manager with the details necessary to start issuing certificates from the LetsEncrypt staging server (*always good to test in staging first!*)

!!! note
    The example above is specific to [Cloudflare](https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/), but the syntax for [other providers](https://cert-manager.io/docs/configuration/acme/dns01/) is similar.

### LetsEncrypt Prod

As you'd imagine, the "prod" version of the LetsEncrypt issues is very similar, and I save this in my flux repo:

```yaml hl_lines="8 15 17-21" title="/letsencrypt-wildcard-cert/cluster-issuer-letsencrypt-prod.yaml"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: batman@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - selector:
        dnsZones:
          - "example.com"
      dns01:
        cloudflare:
          email: batman@example.com
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
```

!!! note
    You'll note that there are two secrets referred to above - `privateKeySecretRef`, referencing `letsencrypt-prod` is for cert-manager to populate as a result of its ACME schenanigans - you don't have to do anything about this particular secret! The cloudflare-specific secret (*and this will change based on your provider*) is expected to be found in the same namespace as the cert-manager itself, and will be discussed when we create our [wildcard certificate](/kubernetes/ssl-certificates/wildcard-certificate/).

## Serving

### How do we know it works?

We're not quite ready to issue certificates yet, but we can now test whether the Issuers are configured correctly for LetsEncrypt. To check their status, **describe** the ClusterIssuers (i.e., `kubectl describe clusterissuer letsencrypt-prod`), which (*truncated*) shows something like this:

```yaml
Status:
  Acme:
    Last Registered Email:  admin@example.com
    Uri:                    https://acme-v02.api.letsencrypt.org/acme/acct/34523
  Conditions:
    Last Transition Time:  2021-11-18T22:54:20Z
    Message:               The ACME account was registered with the ACME server
    Observed Generation:   1
    Reason:                ACMEAccountRegistered
    Status:                True
    Type:                  Ready
Events:                    <none>
```

Provided your account is registered, you're ready to proceed with [creating a wildcard certificate](/kubernetes/ssl-certificates/wildcard-certificate/)!

{% include 'recipe-footer.md' %}

[^1]: Since a ClusterIssuer is not a namespaced resource, it doesn't exist in any specific namespace. Therefore, my assumption is that the `apiTokenSecretRef` secret is only "looked for" when a certificate (*which **is** namespaced*) requires validation.
