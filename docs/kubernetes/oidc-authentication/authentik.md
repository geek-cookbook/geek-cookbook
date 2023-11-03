---
title: Configure K3s for OIDC authentication with Authentik
description: How to configure your Kubernetes cluster for OIDC authentication with Authentik
---
# Authenticate to Kubernetes with OIDC on K3s

This recipe describes how to configure K3s for OIDC authentication against an [authentik][k8s/authentik] instance. 

For details on **why** you'd want to do this, see the [Kubernetes Authentication Guide](/kubernetes/oidc-authentication/).

## Requirements

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) deployed using [K3S](/kubernetes/cluster/k3s)
    * [x] [Authentik][k8s/authentik] deployed per the recipe

## Setup authentik for kube-apiserver

Start by logging into your [authentik][k8s/authentik] instance with a superuser account.

### Create provider

Navigate to **Applications** -> **Providers**, and **Create** a new `OAuth2/OpenID Provider`.

![](/images/authentik-kube-apiserver-1.png)

Give your provider a name (*I use `kube-apiserver`*), and set the following:

* Authentication flow: `default-authentication-flow (Welcome to authentik!)`
* Authorization flow: `default-provider-authorization-implicit-consent (Authorize Application)`
* Client type: `Confidential`

![](/images/authentik-kube-apiserver-2.png)

Scroll down, and set:

* Client ID: `kube-apiserver` *take note, this is non-default*
* Client Secret: `<pick a secret, or use the randomly generated one>`
* Redirect URIs/Origins (RegEx): `http://localhost:18000` [^1]

![](/images/authentik-kube-apiserver-3.png)

Under **Advanced Protocol Settings**, below the set the scopes to include the built-in `email` scope, as well as the extra `oidc-groups` scope you added when [initially setting up authentik][k8s/authentik]:

![](/images/authentik-kube-apiserver-4.png)

Finally, enable **Include claims in id_token**, instructing authentik to send the user claims back with the id token:

![](/images/authentik-kube-apiserver-5.png)


..and click **Finish**. On the following summary page, under **OAuth2 Provider**, take note of the **OpenID Configuration** URL (*`/application/o/kube-apiserver/.well-known/openid-configuration` if you followed my conventions above*) - you'll need this when configuring Kubernetes.

!!! question "What's that redirect URI for?"
    We'll use [kubelogin](https://github.com/int128/kubelogin) to confirm OIDC login is working, which runs locally on port 18000 to provide a web-based OIDC login flow.

### Create application

authentik requires a one-to-one relationship between applications and providers, so navigate to **Applications** -> **Applications**, and **create** an application for your new provider. 

You can name it anything you want (*but it might be more sensible to name it for your provider, rather than a superhero! :superhero:*)

![](/images/authentik-kube-apiserver-6.png)

### Create group

Remember how we setup a groups property-mapper when deploying [authentik][k8s/authentik]? When kube-apiserver requests the `groups` scope from Authentik, the mapper will return all a user's group names.

You can create whatever groups you prefer - later on, you'll configure clusterrolebindings to provide RBAC access to group members. I'd start with a group called `admin-kube-apiserver`, which we'll simply map to the `cluster-admin` clusterrole.

Navigate to **Directory** -> **Groups**, create the necessary groups, and make yourself a member.

## Summary

What have we achieved? We've configured authentik as an OIDC provider, and we've got the details necessary to configure our Kubernetes platform(s) to authenticate against it!

!!! summary "Summary"
    Created:

    * [X] [authentik][k8s/authentik] configured as an OIDC provider for kube-apiserver
    * [X] OIDC parameters, including:
        * [X] OIDC Client id (`kube-apiserver`)
        * [X] OIDC Client secret (`<your chosen secret>`)
        * [X] OIDC Configuration URL (`https://<your-authentic-hosts>/application/o/kube-apiserver/.well-known/openid-configuration`)

What's next? 

Return to the [Kubernetes Authentication Guide](/kubernetes/oidc-authentication/) for instructions re configuring your particular Kubernetes platform!

[^1]: Later on, as we add more applications which need kube-apiserver authentication, we'll add more redirect URIs.

{% include 'recipe-footer.md' %}
