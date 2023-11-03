---
title: Configure EKS for OIDC authentication with Authentik
description: How to configure your EKS Kubernetes cluster for OIDC authentication with Authentik
---
# Authenticate to Kubernetes with OIDC on EKS

This recipe describes how to configure an EKS cluster for OIDC authentication against an [authentik][k8s/authentik] instance. 

For details on **why** you'd want to do this, see the [Kubernetes Authentication Guide](/kubernetes/oidc-authentication/).

## Requirements

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) deployed on Amazon EKS
    * [x] [authentik][k8s/authentik] deployed per the recipe, secured with a valid SSL cert (*no self-signed schenanigans will work here!*)
    * [x] authentik [configured as an OIDC provider for kube-apiserver](/kubernetes/oidc-authentication/authentik/)
    * [x] `eksctl` tool configured and authorized for your IAM account

## Setup EKS for OIDC auth

In order to associate an OIDC provider with your EKS cluster[^1], you'll need (*guess what?*)..

.. some YAML.

Create an EKS magic YAML[^2] like this, and tweak it for your cluster name, region, and issuerUrl:

```yaml title="eks-cluster-setup.yaml"
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: funkypenguin-authentik-test
  region: ap-southeast-2

identityProviders:
  - name: authentik
    type: oidc
    issuerUrl: https://authentik.funkypenguin.de/application/o/kube-apiserver/ # (1)! 
    clientId: kube-apiserver
    usernameClaim: email
    usernamePrefix: 'oidc:'
    groupsClaim: groups
    groupsPrefix: 'oidc:'
```

1. Make sure this ends in a `/`, and doesn't include `.well-known/openid-configuration`

Apply the EKS magic by running `eksctl associate identityprovider -f eks-cluster-setup.yaml`

That's it! It may take a few minutes (you can verify it's ready on your EKS console), but once complete, the authentik provider should be visible in your cluster console, under the "Authentication" tab, as illustrated below:

![](/images/eks-authentic-1.png)

{% include 'kubernetes-oidc-setup.md' %}

## Summary

What have we achieved? 

We've setup our EKS cluster to authenticate against authentik, running on that same cluster! We can now create multiple users (*with multiple levels of access*) without having to provide them with tricky IAM accounts, and deploy kube-apiserver-integrated tools like Kubernetes Dashboard or Weaveworks GitOps for nice secured UIs.

!!! summary "Summary"
    Created:

    * [X] EKS cluster with OIDC authentication against [authentik][k8s/authentik]
    * [X] Ability to support:
        * [X] Kubernetes Dashboard (*coming soon*)
        * [X] Weave GitOps (*coming soon*)
    * [X] We've also retained our static, IAM-based `kubernetes-admin` credentials in case OIDC auth fails at some point (*keep them safe!*)

What's next? 

Deploy Weave GitOps to visualize your Flux / GitOps state, and Kubernetes Dashboard for UI management of your cluster!

[^1]: AWS docs are at https://docs.aws.amazon.com/eks/latest/userguide/authenticate-oidc-identity-provider.html
[^2]: For details on available options, see https://docs.aws.amazon.com/cli/latest/reference/eks/associate-identity-provider-config.html


{% include 'recipe-footer.md' %}
