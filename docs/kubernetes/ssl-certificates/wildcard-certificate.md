# Wildcard Certificate

Now that we have an [Issuer](/kubernetes/ssl-certificates/letsencrypt-issuers/) and the necessary credentials, we can create a wildcard certificate, which we can then feed to our [Ingresses](/kubernetes/ingress/).

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] [Cert-Manager](/kubernetes/ssl-certificates/cert-manager/) deployed to request/renew certificates
    * [x] [LetsEncrypt ClusterIssuers](/kubernetes/ssl-certificates/letsencrypt-issuers/) created using DNS01 validation solvers

Certificates are Kubernetes secrets, and so are subject to the same limitations / RBAC controls as other secrets. Importantly, they are **namespaced**, so it's not possible to refer to a secret in one namespace, from a pod in **another** namespace. This restriction also applies to Ingress resources (*although there are workarounds*) - An Ingress can only refer to TLS secrets in its own namespace.

This behaviour can be prohibitive, because (a) we don't want to have to request/renew certificates for every single FQDN served by our cluster, and (b) we don't want more than one wildcard certificate if possible, to avoid being rate-limited at request/renewal time.

To take advantage of the various workarounds available, I find it best to put the certificates into a dedicated namespace, which I name.. `letsencrypt-wildcard-cert`.

!!! question "Why not the cert-manager namespace?"
    Because cert-manager is a _controller_, whose job it is to act on resources. I should be able to remove cert-manager entirely (even its namespace) from my cluster, and re-add it, without impacting the resources it acts upon. If the certificates lived in the `cert-manager` namespace, then I wouldn't be able to remove the namespace without also destroying the certificates.

    Furthermore, we can't deploy ClusterIssuers (a CRD) in the same kustomization which deploys the helmrelease which creates those CRDs in the first place. Flux won't be able to apply the ClusterIssuers until the CRD is created, and so will fail to reconcile.

## Preparation

### DNS01 Validation Secret

The simplest way to validate ownership of a domain to LetsEncrypt is to use DNS-01 validation. In this mode, we "prove" our ownership of a domain name by creating a special TXT record, which LetsEncrypt will check and confirm for validity, before issuing us any certificates for that domain name.

The [ClusterIssuers we created earlier](/kubernetes/ssl-certificates/letsencrypt-issuers/) included a field `solvers.dns01.cloudflare.apiTokenSecretRef.name`. This value points to a secret (*in the same namespace as cert-manager*) containing credentials necessary to create DNS records automatically. (*again, my examples are for cloudflare, but the [other supported providers](https://cert-manager.io/docs/configuration/acme/dns01/) will have similar secret requirements*)

Thanks to [Sealed Secrets](/kubernetes/sealed-secrets/), we have a safe way of committing secrets into our repository, so to create necessary secret, you'd run something like this:

```bash
  kubectl create secret generic cloudflare-api-token-secret \
  --namespace cert-manager \
  --dry-run=client \
  --from-literal=api-token=gobbledegook -o json \
  | kubeseal --cert <path to public cert> \
  | kubectl create -f - \
  > <path to repo>/cert-manager/sealedsecret-cloudflare-api-token-secret.yaml
```

### Staging Certificate

Finally, we create our certificates! Here's an example certificate resource which uses the letsencrypt-staging issuer (*to avoid being rate-limited while learning!*). I save this in my flux repo as `/letsencrypt-wildcard-cert/certificate-wildcard-cert-letsencrypt-staging.yaml`


```yaml title="/letsencrypt-wildcard-cert/certificate-wildcard-cert-letsencrypt-staging.yaml"
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: letsencrypt-wildcard-cert-example.com-staging
  namespace: letsencrypt-wildcard-cert
spec:
  # secretName doesn't have to match the certificate name, but it may as well, for simplicity!
  secretName: letsencrypt-wildcard-cert-example.com-staging 
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  dnsNames:
    - "example.com"
    - "*.example.com"
```

## Serving

### Did it work?

After committing the above to the repo, provided the YAML syntax is correct, you should end up with a "Certificate" resource in the `letsencrypt-wildcard-cert` namespace. This doesn't mean that the certificate has been issued by LetsEncrypt yet though - describe the certificate for more details, using `kubectl describe certificate -n letsencrypt-wildcard-cert letsencrypt-wildcard-cert-staging`. The `status` field will show you whether the certificate is issued or not:

```yaml
Status:
  Conditions:
    Last Transition Time:  2021-11-19T01:09:32Z
    Message:               Certificate is up to date and has not expired
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2022-02-17T00:09:26Z
  Not Before:              2021-11-19T00:09:27Z
  Renewal Time:            2022-01-18T00:09:26Z
  Revision:                1
```

### Troubleshooting

If your certificate does not become `Ready` within a few minutes [^1], try watching the logs of cert-manager to identify the issue, using `kubectl logs -f -n cert-manager -l app.kubernetes.io/name=cert-manager`.

### Production Certificate

Once you know you can happily deploy a staging certificate, it's safe enough to attempt your "prod" certificate. I save this in my flux repo as `/letsencrypt-wildcard-cert/certificate-wildcard-cert-letsencrypt-prod.yaml`

```yaml title="/letsencrypt-wildcard-cert/certificate-wildcard-cert-letsencrypt-prod.yaml"
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: letsencrypt-wildcard-cert-example.com
  namespace: letsencrypt-wildcard-cert
spec:
# secretName doesn't have to match the certificate name, but it may as well, for simplicity!
  secretName: letsencrypt-wildcard-cert-example.com 
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - "example.com"
  - "*.example.com"
```

Commit the certificate and follow the steps above to confirm that your prod certificate has been issued.

--8<-- "recipe-footer.md"

[^1]: This process can take a frustratingly long time, and watching the cert-manager logs at least gives some assurance that it's progressing!
