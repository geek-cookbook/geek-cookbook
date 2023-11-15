---
title: How to deploy Keycloak on Kubernetes
description: Deploy Keycloak on Kubernetes to provide OIDC to your cluster and workloads
values_yaml_url: https://github.com/bitnami/charts/blob/main/bitnami/keycloak/values.yaml
helm_chart_version: 17.3.x
helm_chart_name: keycloak
helm_chart_repo_name: bitnami
helm_chart_repo_url: oci://registry-1.docker.io/bitnamicharts/keycloak
helmrelease_name: keycloak
helmrelease_namespace: keycloak
kustomization_name: keycloak
slug: KeyCloak
status: new
upstream: https://www.keycloak.org
links:
- name: GitHub Repo
  uri: https://github.com/keycloak/keycloak
---

# KeyCloak installation on Kubernetes

[Keycloak](https://www.keycloak.org/) is "_an open source identity and access management solution_". Using a local database, or a variety of backends (_think [OpenLDAP](/recipes/openldap/)_), you can provide Single Sign-On (SSO) using OpenID, OAuth 2.0, and SAML.

![Keycloak Screenshot](/images/keycloak.png){ loading=lazy }

Keycloak's OpenID provider can also be used to provide [OIDC-based authentication to your Kubernetes cluster](/kubernetes/oidc-authentication/), or in combination with [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/), to protect [vulnerable services](/recipes/autopirate/nzbget/) with an extra layer of authentication.

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

## Configure Keycloak Helm Chart

The following sections detail suggested changes to the values pasted into `/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml` from the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}). The values are already indented correctly to be copied, pasted into the HelmRelease, and adjusted as necessary.

### Ingress

Setup your ingress for the KeyCloak UI, enabling at least `ingress.enabled` as below, and additional TLS options as necessary[^1]:

```yaml hl_lines="4" title="Configure your ingress"
    ingress:
      ## @param ingress.enabled Enable ingress record generation for Keycloak
      ##
      enabled: false
```

Either leave blank to accept the default ingressClassName, or set to whichever [ingress controller](/kubernetes/ingress/) you want to use.

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
~ ❯ k get pods -n keycloak
NAME                                READY   STATUS      RESTARTS        AGE
keycloak-0                          1/1     Running     1 (3d17h ago)   26d
keycloak-postgresql-0               1/1     Running     1 (3d17h ago)   26d
~ ❯
```

Browse to the URL you configured in your ingress above, and confirm that the KeyCloak UI is displayed. Login with the admin user you defined above, and confirm a successful login.

### Create Keycloak user

!!! question "Why are we adding a user when I have an admin user already?"
    Do you keep a spare set of house keys somewhere _other_ than your house? Do you login as `root` onto all your systems? Think of this as the same prinicple - lock the literal `admin` account away somewhere as a "password of last resort", and create a new user for your day-to-day interaction with Keycloak.

Within the "Master" realm (_no need for more realms unless you want to_), navigate to **Manage** -> **Users**, and then click **Add User** at the top right:

![Navigating to the add user interface in Keycloak](/images/keycloak-add-user-1.png){ loading=lazy }

Populate your new user's username (it's the only mandatory field)

![Populating a username in the add user interface in Keycloak](/images/keycloak-add-user-2.png){ loading=lazy }

#### Set Keycloak user credentials

Once your user is created, to set their password, click on the "**Credentials**" tab, and procede to reset it. Set the password to non-temporary, unless you like extra work!

![Resetting a user's password in Keycloak](/images/keycloak-add-user-3.png){ loading=lazy }
## Summary

What have we achieved? We've got Keycloak running and accessible, we've created our normal-use user, and we're ready to flex :muscle: the power of Keycloak to deploy an [OIDC provider for Kubernetes](/kubernetes/oidc-authentication/), or to provide OIDC to [Traefik Forward Auth][tfa] to protect vulnerable UIs!

!!! summary "Summary"
    Created:

    * [X] Keycloak running and ready for authentication :lock: !

    Next:

    * [ ] Configure [Kubernetes OIDC authentication](/kubernetes/oidc-authentication/), unlocking production readiness as well as the [Kubernetes Dashboard][k8s/dashboard] and Weave GitOps UIs (*coming soon*)

{% include 'recipe-footer.md' %}

[^1]: There's a trick to using a single cert across multiple Ingresses or IngressRoutes (coming soon)