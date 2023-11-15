---
title: Configure Kubernetes for OIDC authentication
description: How to configure your Kubernetes cluster for OIDC authentication, so that you can provide RBAC-protected access to multiple users
---
# Authenticate to Kubernetes with OIDC

So you've got a shiny Kubernetes cluster, and you're probably using the `cluster-admin` config which was created as a result of the initial bootstrap.

While this hard-coded, `cluster-admin` credential is OK while you're bootstrapping, and should be safely stored somewhere as a password-of-last-resort, you'll probably want to secure your cluster with something a little more... secure.

Consider the following downsides to a single, static, long-lived credential:

1. It can get stolen
2. It can't be shared (*you might want to give your team access to the cluster, or even a limited subset of admin access*)
3. It can't be MFA'd
4. Using it for the Kubernetes Dashboard (*copying and pasting into a browser window*) is a huge PITA

True to form, Kubernetes doesn't provide any turnkey access solution, but all the necessary primitives (*RBAC, api-server arguments, etc*) to build your own solution, starting with [authenticating and authorizing access to the apiserver](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#configuring-the-api-server).

## Requirements

Securing access to Kubernetes' API server requires an OIDC provider, be it an external service like Auth0 or Octa, or a self-hosted, open-source IDP like Keycloak or [authentik][k8s/authentik].

### Setup Provider

1. Setup [Authentik for Kubernetes API authentication](/kubernetes/authentication/authentik/)
2. Keycloak (*coming soon*)

### Configure Kubernetes for OIDC auth

Once you've configured your OIDC provider, review the following, based on your provider and your Kubernetes platform:

#### Authentik

* [Authenticate K3s with Authentik as an OIDC provider](/kubernetes/oidc-authentication/k3s-authentik/)
* [Authenticate EKS with Authentik as an OIDC provider](/kubernetes/oidc-authentication/eks-authentik/)
* Authenticate a kubeadm cluster using Authentik as an OIDC provider (*coming soon*)

--8<-- "common-links.md"