## Preparation

### {{ page.meta.slug }} Namespace

We need a namespace to deploy our HelmRelease and associated YAMLs into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `/bootstrap/namespaces/namespace-{{ page.meta.helmrelease_namespace }}.yaml`:

```yaml title="/bootstrap/namespaces/namespace-{{ page.meta.helmrelease_namespace }}.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: {{ page.meta.helmrelease_namespace }}
```
