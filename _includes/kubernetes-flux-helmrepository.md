### {{ page.meta.slug }} HelmRepository

We're going to install the {{ page.slug }} helm chart from the [{{ page.meta.helm_chart_repo_name }}]({{ page.meta.helm_chart_repo_url }}) repository, so I create the following in my flux repo (*assuming it doesn't already exist*):

```yaml title="/bootstrap/helmrepositories/helmrepository-{{ page.meta.helm_chart_repo_name }}.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: {{ page.meta.helm_chart_repo_name }}
  namespace: flux-system
spec:
  interval: 15m
  url: {{ page.meta.helm_chart_repo_url }}
```
