### Kustomization

Now that the "global" elements of this deployment (*just the HelmRepository in this case*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/{{ page.meta.helmrelease_namespace }}/`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-{{ page.meta.kustomization_name }}.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: {{ page.meta.kustomization_name }}
  namespace: flux-system
spec:
  interval: 30m
  path: ./{{ page.meta.helmrelease_namespace }}
  prune: true # remove any elements later removed from the above path
  timeout: 10m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  healthChecks:
    - apiVersion: helm.toolkit.fluxcd.io/v2beta1
      kind: HelmRelease
      name: {{ page.meta.helmrelease_name }}
      namespace: {{ page.meta.helmrelease_namespace }}
```

--8<-- "premix-cta-kubernetes.md"