## Install {{ page.meta.slug }}!

Commit the changes to your flux repository, and either wait for the reconciliation interval, or force  a reconcilliation using `flux reconcile source git flux-system`. You should see the kustomization appear...

```bash
~ ❯ flux get kustomizations {{ page.meta.kustomization_name }}
NAME     	READY	MESSAGE                       	REVISION    	SUSPENDED
{{ page.meta.kustomization_name }}	True 	Applied revision: main/70da637	main/70da637	False
~ ❯
```

The helmrelease should be reconciled...

```bash
~ ❯ flux get helmreleases -n {{ page.meta.helmrelease_namespace }} {{ page.meta.helmrelease_name }}
NAME     	READY	MESSAGE                         	REVISION	SUSPENDED
{{ page.meta.helmrelease_name }}	True 	Release reconciliation succeeded	v{{ page.meta.helm_chart_version }}  	False
~ ❯
```

And you should have happy pods in the {{ page.meta.helmrelease_namespace }} namespace:

```bash
~ ❯ k get pods -n {{ page.meta.helmrelease_namespace }} -l app.kubernetes.io/name={{ page.meta.helmrelease_name }}
NAME                                  READY   STATUS    RESTARTS   AGE
{{ page.meta.helmrelease_name }}-7c94b7446d-nwsss   1/1     Running   0          5m14s
~ ❯
```