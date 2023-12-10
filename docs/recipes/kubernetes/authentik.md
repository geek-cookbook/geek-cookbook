---
title: How to deploy authentik on Kubernetes
description: Deploy authentik on Kubernetes to provide SSO to your cluster and workloads
values_yaml_url: https://github.com/goauthentik/helm/blob/main/charts/authentik/values.yaml
helm_chart_version: 2023.10.x
helm_chart_name: authentik
helm_chart_repo_name: authentik
helm_chart_repo_url: https://charts.goauthentik.io/
helmrelease_name: authentik
helmrelease_namespace: authentik
kustomization_name: authentik
slug: authentik
status: new
upstream: https://goauthentik.io
links:
- name: Discord
  uri: https://goauthentik.io/discord
- name: GitHub Repo
  uri: https://github.com/goauthentik/authentik
---

# authentik on Kubernetes

authentik[^1] is an open-source Identity Provider, focused on flexibility and versatility. With authentik, site administrators, application developers, and security engineers have a dependable and secure solution for authentication in almost any type of environment.

![authentik login](/images/authentik.png){ loading=lazy }

There are robust recovery actions available for the users and applications, including user profile and password management. You can quickly edit, deactivate, or even impersonate a user profile, and set a new password for new users or reset an existing password.

You can use authentik in an existing environment to add support for new protocols, so introducing authentik to your current tech stack doesn't present re-architecting challenges. We already support all of the major providers, such as OAuth2, SAML, [LDAP][openldap] :t_rex:, and SCIM, so you can pick the protocol that you need for each application.

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
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-dnsendpoint.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

## Configure authentik Helm Chart

The following sections detail suggested changes to the values pasted into `/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml` from the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}). The values are already indented correctly to be copied, pasted into the HelmRelease, and adjusted as necessary.

!!! tip
    Confusingly, the authentik helm chart defaults to having the bundled redis and postgresql **disabled**, but the [authentik Kubernetes install](https://goauthentik.io/docs/installation/kubernetes/) docs require that they be enabled. Take care to change the respective `enabled: false` values to `enabled: true` below.

### Set authentik secret key

Authentik needs a secret key for signing cookies (*not singing for cookies! :cookie:*), so set it below, and don't change it later (*or feed it after midnight!*):

```yaml hl_lines="6" title="Set mandatory secret key"
    authentik:
      # -- Log level for server and worker
      log_level: info
      # -- Secret key used for cookie singing and unique user IDs,
      # don't change this after the first install
      secret_key: "ilovesingingcookies"
```

### Set bootstrap credentials

By default, when you install the authentik helm chart, you'll get to set your admin user's (`akadmin`) when you first login. You can pre-configure this password by setting the `AUTHENTIK_BOOTSTRAP_PASSWORD` env var as illustrated below.

If you're after a more hands-off implementation, you can also pre-set a "bootstrap token", which can be used to interact with the authentik API programatically (*see example below*):

```yaml hl_lines="2-3" title="Optionally pre-configure your bootstrap secrets"
    env:
      AUTHENTIK_BOOTSTRAP_PASSWORD: "iamusedbyhumanz",
      AUTHENTIK_BOOTSTRAP_TOKEN: "iamusedbymachinez"
```

### Configure Redis for authentik

authentik uses Redis as the broker for [Celery](https://docs.celeryq.dev/en/stable/) background tasks. The authentik helm chart defaults to provisioning an 8Gi PVC for redis, which seems like overkill for a simple broker. You can tweak the size of the Redis PVC by setting:

```yaml hl_lines="4" title="1Gi should be fine for redis"
    redis:
      master:
        persistence:
          size: 1Gi
```

### Configure PostgreSQL for authentik

Although technically you **can** leave the PostgreSQL password blank, authentik-server will just error with an error like `fe_sendauth: no password supplied`, so ensure you set the password, both in `authentik.postgresql.password` and in `postgresql.postgresqlPassword`:

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

Setup your ingress for the authentik UI. If you plan to add outposts to proxy other un-authenticated endpoints later, this is where you'll add them:

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

Browse to the URL you configured in your ingress above, and confirm that the authentik UI is displayed.

## Create your admin user

You may be a little confused re how to login for the first time. If you didn't use a bootstrap password as above, you'll want to go to `https://<ingress-host-name>/if/flow/initial-setup/`, and set an initial password for your `akadmin` user.

Now store the `akadmin` password somewhere safely, and proceed to create your own user account (*you'll presumably want to use your own username and email address*).

Navigate to **Admin Interface** --> **Directory** --> **Users**, and create your new user. Edit your user and manually set your password.

Next, navigate to **Directory** --> **Groups**, and edit the **authentik Admins** group. Within the group, click the **Users** tab to add your new user to the **authentik Admins** group.

Eureka! :tada: 

Your user is now an authentik superuser. Confirm this by logging out as **akadmin**, and logging back in with your own credentials.

## Summary

What have we achieved? We've got authentik running and accessible, we've created a superuser account, and we're ready to flex :muscle: the power of authentik to deploy an OIDC provider for Kubernetes, or simply secure unprotected UIs with proxy outposts!

!!! summary "Summary"
    Created:

    * [X] authentik running and ready to "authentikate" :lock: !

    Next:

    * [ ] Configure [Kubernetes OIDC authentication](/kubernetes/oidc-authentication/), unlocking production readiness as well as the [Kubernetes Dashboard][k8s/dashboard] and Weave GitOps UIs (*coming soon*)

{% include 'recipe-footer.md' %}

[^1]: Yes, the lower-case thing bothers me too. That's how the official docs do it though, so I'm following suit.