---
title: How to deploy Authentik on Kubernetes
description: Deploy Authentik on Kubernetes to provide SSO to your cluster and workloads
values_yaml_url: https://github.com/goauthentik/helm/blob/main/charts/authentik/values.yaml
helm_chart_version: 2023.10.x
helm_chart_name: authentik
helm_chart_repo_name: authentik
helm_chart_repo_url: https://charts.goauthentik.io/
helmrelease_name: authentik
helmrelease_namespace: authentik
kustomization_name: authentik
slug: Authentik
status: new
github_repo: https://github.com/goauthentik/authentik
upstream: https://goauthentik.io
links:
- name: Discord
  uri: https://goauthentik.io/discord
---

# Authentik on Kubernetes

Authentik is an open-source Identity Provider focused on flexibility and versatility. It not only supports modern authentication standards (*like OIDC*), but includes "outposts" to provide support for less-modern  protocols such as [LDAP][openldap] :t_rex:, or basic authentication proxies.

![Authentik login](/images/authentik.png){ loading=lazy }

See a comparison with other IDPs [here](https://goauthentik.io/#comparison).

## {{ page.meta.slug }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] An [Ingress controller](/kubernetes/ingress/) to route incoming traffic to services
    * [x] [Persistent storage](/kubernetes/persistence/) to store persistent stuff

    Optional:

    * [ ] [External DNS](/kubernetes/external-dns/) to create an DNS entry the "flux" way

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-dnsendpoint.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

## Configure Authentik Helm Chart

The following sections detail suggested changes to the values pasted into `/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml` from the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}). The values are already indented correctly to be copied, pasted into the HelmRelease, and adjusted as necessary.

!!! tip
    Confusingly, the Authentik helm chart defaults to having the bundled redis and postgresql **disabled**, but the [Authentik Kubernetes install](https://goauthentik.io/docs/installation/kubernetes/) docs require that they be enabled. Take care to change the respective `enabled: false` values to `enabled: true` below.

### Set bootstrap credentials

By default, when you install the Authentik helm chart, you'll get to set your admin user's (`akadmin`) when you first login. You can pre-configure this password by setting the `AUTHENTIK_BOOTSTRAP_PASSWORD` env var as illustrated below.

If you're after a more hands-off implementation[^1], you can also pre-set a "bootstrap token", which can be used to interact with the Authentik API programatically (*see example below*):

```yaml hl_lines="2-3" title="Optionally pre-configure your bootstrap secrets"
    env:
      AUTHENTIK_BOOTSTRAP_PASSWORD: "iamusedbyhumanz"
      AUTHENTIK_BOOTSTRAP_TOKEN: "iamusedbymachinez"
```

### Configure Redis for Authentik

Authentik uses Redis as the broker for [Celery](https://docs.celeryq.dev/en/stable/) background tasks. The Authentik helm chart defaults to provisioning an 8Gi PVC for redis, which seems like overkill for a simple broker. You can tweak the size of the Redis PVC by setting:

```yaml hl_lines="4" title="1Gi should be fine for redis"
    redis:
      master:
        persistence:
          size: 1Gi
```

### Configure PostgreSQL for Authentik

Depending on your risk profile / exposure, you may want to set a secure PostgreSQL password, or you may be content to leave the default password blank.

At the very least, you'll want to set the following

```yaml hl_lines="3 6" title="Set a secure Postgresql password"
    authentik:
      postgresql:
        password: "Iamaverysecretpassword"

    postgresql:
      postgresqlPassword: "Iamaverysecretpassword"
```

As with Redis above, you may feel (*like I do*) that provisioning an 8Gi PVC for a database containing 1 user and a handful of app configs is overkill. You can adjust the size of the PostgreSQL PVC by setting:

```yaml  hl_lines="3" title="1Gi is fine for a small database"
    postgresql:
      persistence:
        size: 1Gi 
```

### Ingress

Setup your ingress for the Authentik UI. If you plan to add outposts to proxy other un-authenticated endpoints later, this is where you'll add them:

```yaml hl_lines="3 7" title="Configure your ingress"
    ingress:
      enabled: true
      ingressClassName: "nginx" # (1)!
      annotations: {}
      labels: {}
      hosts:
        - host: authentik.example.com
          paths:
            - path: "/"
              pathType: Prefix
      tls: []
```

1. Either leave blank to accept the default ingressClassName, or set to whichever [ingress controller](/kubernetes/ingress/) you want to use.

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
~ ❯ k get pods -n authentik
NAME                                READY   STATUS      RESTARTS        AGE
authentik-redis-master-0            1/1     Running     1 (3d17h ago)   26d
authentik-server-548c6d4d5f-ljqft   1/1     Running     1 (3d17h ago)   20d
authentik-postgresql-0              1/1     Running     1 (3d17h ago)   26d
authentik-worker-7bb8f55bcb-5jwrr   1/1     Running     0               23h
~ ❯
```

Browse to the URL you configured in your ingress above, and confirm that the Authentik UI is displayed.

## Create your admin user

You may be a little confused re how to login for the first time. If you didn't use a bootstrap password as above, you'll want to go to `https://<ingress-host-name>/if/flow/initial-setup/`, and set an initial password for your `akadmin` user.

Now store the `akadmin` password somewhere safely, and proceed to create your own user account (*you'll presumably want to use your own username and email address*).

Navigate to **Admin Interface** --> **Directory** --> **Users**, and create your new user. Edit your user and manually set your password.

Next, navigate to **Directory** --> **Groups**, and edit the **authentik Admins** group. Within the group, click the **Users** tab to add your new user to the **authentik Admins** group.

Eureka! :tada: 

Your user is now an Authentik superuser. Confirm this by logging out as **akadmin**, and logging back in with your own credentials.

## Summary

What have we achieved? We've got Authentik running and accessible, we've created a superuser account, and we're ready to flex :muscle: the power of Authentik to deploy an OIDC provider for Kubernetes, or simply secure unprotected UIs with proxy outposts!

!!! summary "Summary"
    Created:

    * [X] Authentik running and ready to "authentikate" :lock: !

    Next:

    * [ ] Configure Kubernetes for OIDC authentication, unlocking production readiness as well as the Kubernetes Dashboard in Weave GitOps UIs (*coming soon*)

{% include 'recipe-footer.md' %}

[^1]: I use the bootstrap token with an ansible playbook which provisions my users / apps using the Authentik API