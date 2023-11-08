---
title: Use OAuth2 proxy on Kubernetes to secure access
description: Deploy oauth2-proxy on Kubernetes to provide SSO to your cluster and workloads
values_yaml_url: https://github.com/oauth2-proxy/manifests/blob/main/helm/oauth2-proxy/values.yaml
helm_chart_version: 6.18.x
helm_chart_name: oauth2-proxy
helm_chart_repo_name: oauth2-proxy
helm_chart_repo_url: https://oauth2-proxy.github.io/manifests/
helmrelease_name: oauth2-proxy
helmrelease_namespace: kubernetes-dashboard
kustomization_name: oauth2-proxy
slug: OAuth2 Proxy
status: new
upstream: https://oauth2-proxy.github.io/oauth2-proxy/
links:
- name: GitHub Repo
  uri: https://github.com/oauth2-proxy/oauth2-proxy
- name: Helm Chart
  uri: https://github.com/oauth2-proxy/manifests/tree/main/helm/oauth2-proxy
---

# Using OAuth2 proxy for Kubernetes Dashboard

[OAuth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/) was once a bit.ly project, but was officially archived in Sept 2018. It lives on though, at https://github.com/oauth2-proxy/oauth2-proxy.

OAuth2-proxy is a lightweight proxy which you put **in front of** your vulnerable services, enforcing an OAuth authentication against an [impressive collection of providers](https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider) (*including generic OIDC*) before the backend service is displayed to the calling user.

![OAuth2-proxy architecture](/images/oauth2-proxy.png){ loading=lazy }

This recipe will describe setting up OAuth2 Proxy for the purposes of passing authentication headers to [Kubernetes Dashboard][k8s/dashboard], which doesn't provide its own authentication, but instead relies on Kubernetes' own RBAC auth.

In order to view your Kubernetes resources on the dashboard, you either create a fully-privileged service account (*yuk! :face_vomiting:*), copy and paste your own auth token upon login (*double yuk! :face_vomiting::face_vomiting:*), or use OAuth2 Proxy to authenticate against the kube-apiserver on your behalf, and pass the authentication token to [Kubernetes Dashboard][k8s/dashboard] (*like a boss! :muscle:*)

If you're after a generic authentication middleware which **doesn't** need to pass OAuth headers, then [Traefik Forward Auth][tfa] is a better option, since it supports multiple backends in "auth host" mode.

## {{ page.meta.slug }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/), configured for [OIDC authentication](/kubernetes/oidc-authentication/) against a supported [provider](/kubernetes/oidc-authentication/providers/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] An [Ingress controller](/kubernetes/ingress/) to route incoming traffic to services

    Optional:

    * [ ] [External DNS](/kubernetes/external-dns/) to create an DNS entry the "flux" way
    * [ ] [Persistent storage](/kubernetes/persistence/) if you want to use Redis for session persistence

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

## Configure OAuth2 Proxy

The following sections detail suggested changes to the values pasted into `/{{ page.meta.helmrelease_namespace }}/helmrelease-{{ page.meta.helmrelease_name }}.yaml` from the {{ page.meta.slug }} helm chart's [values.yaml]({{ page.meta.values_yaml_url }}). The values are already indented correctly to be copied, pasted into the HelmRelease, and adjusted as necessary.

### OAuth2 Proxy Config

Set your `clientID` and `clientSecret` to match what you've setup in your OAuth provider. You can choose whatever you like for your `cookieSecret`! :cookie:

```yaml hl_lines="5 7 13 32"
    config:
      # Add config annotations
      annotations: {}
      # OAuth client ID
      clientID: "XXXXXXX"
      # OAuth client secret
      clientSecret: "XXXXXXXX"
      # Create a new secret with the following command
      # openssl rand -base64 32 | head -c 32 | base64
      # Use an existing secret for OAuth2 credentials (see secret.yaml for required fields)
      # Example:
      # existingSecret: secret
      cookieSecret: "XXXXXXXXXXXXXXXX"
      # The name of the cookie that oauth2-proxy will create
      # If left empty, it will default to the release name
      cookieName: ""
      google: {}
        # adminEmail: xxxx
        # useApplicationDefaultCredentials: true
        # targetPrincipal: xxxx
        # serviceAccountJson: xxxx
        # Alternatively, use an existing secret (see google-secret.yaml for required fields)
        # Example:
        # existingSecret: google-secret
        # groups: []
        # Example:
        #  - group1@example.com
        #  - group2@example.com
      # Default configuration, to be overridden
      configFile: |-
        email_domains = [ "*" ] # (1)!
        upstreams = [ "http://kubernetes-dashboard" ] # (2)!
```

1. Accept any emails passed to us by the auth provider, which we fully control. You might do this differently if you were using an auth provider like Google or GitHub
2. Set `upstreams[]` to match the backend service you want to protect, in this case, the kubernetes-dashboard service in the same namespace. [^1]

### Set ExtraArgs

Take note of the following, specifically:

```yaml
extraArgs:
  provider: oidc
  provider-display-name: "Authentik"
  skip-provider-button: "true"
  pass-authorization-header: "true" # (1)!
  redis-connection-url: "redis://redis-master" # if you want to use redis
  session-store-type: redis # alternative is to use cookies
  cookie-refresh: 15m
```

1. This is critically important, and is what makes OAuth2 Proxy suited to this task. We need the authorization headers produced from the OIDC transaction to be passed to [Kubernetes Dashboard][k8s/dashboard], so that it can interact with kube-apiserver on our behalf.

### Setup Ingress

Now you'll need an ingress, but note that this'll be the ingress you'll want to use for the [Kubernetes Dashboard][k8s/dashboard], so you'll want something like the following:

```yaml hl_lines="2 3 9"
    ingress:
      enabled: true
      className: nginx
      path: /
      # Only used if API capabilities (networking.k8s.io/v1) allow it
      pathType: ImplementationSpecific
      # Used to create an Ingress record.
      hosts:
        - kubernetes-dashboard.example.com
```

{% include 'kubernetes-flux-check.md' %}

## Is it working?

Browse to the URL you configured in your ingress above, and confirm that you're prompted to log into your OIDC provider.

## Summary

What have we achieved? We're half-way to getting [Kubernetes Dashboard][k8s/dashboard] working against our OIDC-enabled cluster. We've got OAuth2 Proxy authenticating against our OIDC provider, and passing on the auth headers to the upstream.

!!! summary "Summary"
    Created:

    * [X] OAuth2 Proxy on Kubernetes, running and ready pass auth headers to [Kubernetes Dashboard][k8s/dashboard]

    Next:

    * [ ] Deploy [[Kubernetes Dashboard][k8s/dashboard]][kuberetesdashboard], protected by the upstream to OAuth2 Proxy

{% include 'recipe-footer.md' %}

[^1]: While you might, like me, hope that since `upstreams` is a list, you might be able to use one OAuth2 Proxy instance in front of multiple upstreams. Sadly, the intention here is to split the upstream by path, not to provide entirely different upstreams based FQDN. Thus, you're stuck with one OAuth2 Proxy per protected instance.