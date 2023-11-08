---
title: Deploy Kubernetes Dashboard with OIDC token auth
description: Here's how to deploy the Kubernetes Dashboard in your cluster, and autheticate with a bearer token from your OIDC-enabled cluster.
values_yaml_url: https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard/6.0.8
helm_chart_version: 6.0.x
helm_chart_name: kubernetes-dashboard
helm_chart_repo_name: kubernetes-dashboard
helm_chart_repo_url: https://kubernetes.github.io/dashboard/
helmrelease_name: kubernetes-dashboard
helmrelease_namespace: kubernetes-dashboard
kustomization_name: kubernetes-dashboard
slug: Dashboard
status: new
upstream: https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
links:
- name: GitHub Repo
  uri: https://github.com/kubernetes/dashboard
---

# Kubernetes Dashboard (with OIDC token auth)

Kubernetes Dashboard is the polished, general purpose, web-based UI for Kubernetes clusters. It allows users to manage applications running in the cluster and troubleshoot them, as well as manage the cluster itself.

![authentik login](/images/kubernetes-dashboard.png){ loading=lazy }

Importantly, the Dashboard interacts with the kube-apiserver using the credentials you give it. While it's possible to just create a `cluster-admin` service account, and hard-code the necessary service account into Dashboard, this is far less secure, since you're effectively granting anyone with HTTP access to the dashboard full access to your cluster[^1].

There are [several ways to pass a Kubernetes Dashboard](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md) token, this recipe will focus on the [Authentication Header method](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md#authorization-header), under which every request to the dashboard includes the `Authorization: Bearer <token>` header.

We'll utilize [OAuth2 Proxy][k8s/oauth2proxy], integrated with our [OIDC-enabled cluster](/kubernetes/oidc-authentication/), to achieve this seamlessly and securely.

## {{ page.meta.slug }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/), configured for [OIDC authentication](/kubernetes/oidc-authentication/) against a supported [provider](/kubernetes/oidc-authentication/providers/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] [OAuth2 Proxy][k8s/oauth2proxy] to pass the necessary authentication token

{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-dnsendpoint.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

!!! warning "Beware v3.0.0-alpha0"
    The Dasboard repo's `master` branch has already been updated to a (breaking) new architecture. Since we're not lunatics, we're going to use the latest stable `6.0.x` instead! For this reason, take care to avoid the `values.yaml` in the repo, but use the link to artifacthub instead.

The following sections detail suggested changes to the values pasted into `/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml` from the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}). The values are already indented correctly to be copied, pasted into the HelmRelease, and adjusted as necessary.

## Enable insecure mode

Because we're using OAuth2 Proxy in front of Dashboard, the incoming request will be HTTP from Dashboard's perspective, rather than HTTPS. We're happy to permit this, so make at least the following change to `ExtraArgs` below:

```yaml hl_lines="3"
extraArgs:
#   - --enable-skip-login
   - --enable-insecure-login
```

{% include 'kubernetes-flux-check.md' %}

## Is that all?

Feels too easy, doesn't it?

The reason is that all the hard work (*ingress, OIDC authentication, etc*) is all handled by [OAuth2 Proxy][k8s/oauth2proxy], so provided that's been deployed and tested, you're good-to-go!

Browse to the URL you configured in your OAuth2 Proxy ingress, log into your OIDC provider, and your should be directed to your Kubernetes Dashboard UI, with all the privileges your authentication token gets you :muscle:

## Summary

What have we achieved? We've got a dashboard for Kubernetes, dammit! That's **amaaazing**!

And even better, it doesn't rely on some hacky copy/pasting of tokens, or disabling security, but it uses our existing, trusted OIDC cluster auth. This also means that you can grant other users access to the dashboard with more restrictive (*i.e., read-only access*) privileges.

!!! summary "Summary"
    Created:

    * [X] Kubernetes Dashboard deployed, authenticated with [OIDC-enabled cluster](/recipes/kubernetes/oidc-authentication/) using an Authorization Header with a bearer token, magically provided by [OAuth2 Proxy][k8s/oauth2proxy]!

{% include 'recipe-footer.md' %}

[^1]: Plus, you wouldn't be able to do tiered access in this scenario