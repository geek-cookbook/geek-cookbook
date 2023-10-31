### {{ page.meta.slug }} HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy {{ page.meta.helmrelease_name }} into the cluster. We start with a basic HelmRelease YAML, like this example:

```yaml title="/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ page.meta.helmrelease_name }}
  namespace: {{ page.meta.helmrelease_namespace }}
spec:
  chart:
    spec:
      chart: {{ page.meta.helmrelease_namespace }}
      version: {{ page.meta.helm_chart_version }} # auto-update to semver bugfixes only (1)
      sourceRef:
        kind: HelmRepository
        name: {{ page.meta.helm_chart_repo_name }}
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: {{ page.meta.helmrelease_namespace }}
  values: # paste contents of upstream values.yaml below, indented 4 spaces (2)
```

1. I like to set this to the semver minor version of the {{ page.meta.slug }} current helm chart, so that I'll inherit bug fixes but not any new features (*since I'll need to manually update my values to accommodate new releases anyway*)
2. Paste the full contents of the upstream [values.yaml]({{ page.meta.values_yaml_url }}) here, indented 4 spaces under the `values:` key

If we deploy this helmrelease as-is, we'll inherit every default from the upstream {{ page.meta.slug }} helm chart. That's probably hardly ever what we want to do, so my preference is to take the entire contents of the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}), and to paste these (*indented*), under the `values` key. This means that I can then make my own changes in the context of the entire values.yaml, rather than cherry-picking just the items I want to change, to make future chart upgrades simpler.

--8<-- "kubernetes-why-not-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration.