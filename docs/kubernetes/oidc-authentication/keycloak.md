---
title: Configure K3s for OIDC authentication with Keycloak
description: How to configure your Kubernetes cluster for OIDC authentication with Keycloak
---
# Authenticate to Kubernetes with OIDC on K3s

This recipe describes how to configure K3s for OIDC authentication against a [keycloak][k8s/keycloak] instance. 

For details on **why** you'd want to do this, see the [Kubernetes Authentication Guide](/kubernetes/oidc-authentication/).

## Requirements

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) deployed using [K3S](/kubernetes/cluster/k3s)
    * [x] [Keycloak][k8s/keycloak] deployed per the recipe

## Setup Keycloak for kube-apiserver

Start by logging into your [Keycloak][k8s/keycloak] instance with a privileged account.

### Create client

Navigate to **Configure** -> **Clients**, and **Create** a new client. I set the client ID to `kube-apiserver` (*you can't change it later*):

![](/images/keycloak-kube-apiserver-1.png)

That's it! You created your client!

Easy eh?

Of course, it won't work yet, so there are a few tweaks we'll need..

#### Access Type

Change **Access Type** to `confidential` - this indicates to KeyCloak that your client can be trusted to keep a secret safe, and thus that secret can be used in the OIDC credentials exchange.

![](/images/keycloak-kube-apiserver-2.png)

#### Redirect URIs

Edit **Redirect URIs**, and add `http://localhost:18000` [^1]

![](/images/keycloak-kube-apiserver-3.png)

!!! question "What's that redirect URI for?"
    We'll use [kubelogin](https://github.com/int128/kubelogin) to confirm OIDC login is working, which runs locally on port 18000 to provide a web-based OIDC login flow.

#### Get credentials

Save your settings, and observe that upon refresh, a new **Credentials** tab becomes available..

![](/images/keycloak-kube-apiserver-4.png)

Navigate to **Credentials**, and make a note of the automatically generated client secret. You'll need this later for configuring your OIDC login.

### Add mapper for groups

Finally, because we prefer to assign privileges to groups, rather than to individual users, navigate to **Mappers**, and create a new mapper as illustrated below:

![](/images/keycloak-kube-apiserver-5.png)

This will send a `groups` claim back to your OIDC client, with a list of your group memberships.

### Create group

You can create whatever groups you prefer - later on, you'll configure clusterrolebindings to provide RBAC access to group members. I'd start with a group called `admin-kube-apiserver`, which we'll simply map to the `cluster-admin` clusterrole.

Navigate to **Manage** -> **Groups**, create the necessary groups, and make yourself a member.

## Summary

What have we achieved? We've configured Keycloak as an OIDC provider, and we've got the details necessary to configure our Kubernetes platform(s) to authenticate against it!

!!! summary "Summary"
    Created:

    * [X] [keycloak][k8s/keycloak] configured as an OIDC provider for kube-apiserver
    * [X] OIDC parameters, including:
        * [X] OIDC Client id (`kube-apiserver`)
        * [X] OIDC Client secret (`<a randomly-generated secret>`)
        * [X] OIDC Configuration URL (`https://<your-keycloak-host>/auth/realms/master/.well-known/openid-configuration`)

What's next? 

Return to the [Kubernetes Authentication Guide](/kubernetes/oidc-authentication/) for instructions re configuring your particular Kubernetes platform!

[^1]: Later on, as we add more applications which need kube-apiserver authentication, we'll add more redirect URIs.

{% include 'recipe-footer.md' %}
