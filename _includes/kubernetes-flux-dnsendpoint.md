### {{ page.meta.slug }} DNSEndpoint

If, like me, you prefer to create your DNS records the "GitOps way" using [ExternalDNS](/kubernetes/external-dns/), create something like the following example to create a DNS entry for your Authentik ingress:

```yaml title="/{{ page.meta.helmrelease_namespace }}/dnsendpoint-{{ page.meta.helmrelease_name }}.example.com.yaml"
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: "{{ page.meta.helmrelease_name }}.example.com"
  namespace: {{ page.meta.helmrelease_namespace }}
spec:
  endpoints:
  - dnsName: "{{ page.meta.helmrelease_name }}.example.com"
    recordTTL: 180
    recordType: CNAME
    targets:
    - "traefik-ingress.example.com"  
```

!!! tip
    Rather than creating individual A records for each host, I prefer to create one A record (*`nginx-ingress.example.com` in the example above*), and then create individual CNAME records pointing to that A record.
