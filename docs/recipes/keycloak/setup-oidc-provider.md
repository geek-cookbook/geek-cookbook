---
title: How to setup OIDC provider in Keycloak
description: Having an authentication provider is not much use until you start authenticating things against it! In order to authenticate against Keycloak using OpenID Connect (OIDC), which is required for Traefik Forward Auth, we'll setup a client in Keycloak...
---
# Add OIDC Provider to Keycloak

!!! warning
    This is not a complete recipe - it's an optional component of the [Keycloak recipe](/recipes/keycloak/), but has been split into its own page to reduce complexity.

Having an authentication provider is not much use until you start authenticating things against it! In order to authenticate against Keycloak using OpenID Connect (OIDC), which is required for [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/), we'll setup a client in Keycloak...

## Ingredients

!!! Summary
    Existing:

    * [X] [Keycloak](/recipes/keycloak/) recipe deployed successfully

    New:

    * [ ] The URI(s) to protect with the OIDC provider. Refer to the [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/) recipe for more information  

## Preparation

### Create Client

Within the "Master" realm (*no need for more realms yet*), navigate to **Clients**, and then click **Create** at the top right:

![Navigating to the add user interface in Keycloak](/images/keycloak-add-client-1.png){ loading=lazy }

Enter a name for your client (*remember, we're authenticating **applications** now, not users, so use an application-specific name*):

![Adding a client in Keycloak](/images/keycloak-add-client-2.png){ loading=lazy }

### Configure Client

Once your client is created, set at **least** the following, and click **Save**

* **Access Type** : Confidential
* **Valid Redirect URIs** : <The URIs you want to protect\>

![Set Keycloak client to confidential access type, add redirect URIs](/images/keycloak-add-client-3.png){ loading=lazy }

### Retrieve Client Secret

Now that you've changed the access type, and clicked **Save**, an additional **Credentials** tab appears at the top of the window. Click on the tab, and capture the Keycloak-generated secret. This secret, plus your client name, is required to authenticate against Keycloak via OIDC.

![Capture client secret from Keycloak](/images/keycloak-add-client-4.png){ loading=lazy }

## Summary

We've setup an OIDC client in Keycloak, which we can now use to protect vulnerable services using [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/). The OIDC URL provided by Keycloak in the master realm, is `https://<your-keycloak-url>/realms/master/.well-known/openid-configuration`

!!! Summary
    Created:

    * [X] Client ID and Client Secret used to authenticate against Keycloak with OpenID Connect

--8<-- "recipe-footer.md"
