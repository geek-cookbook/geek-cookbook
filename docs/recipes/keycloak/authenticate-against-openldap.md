---
title: Integrate LDAP server with Keycloak for user federation
description: Here's how we'll add an LDAP provider to our Keycloak server for user federation.
---
# Authenticate Keycloak against OpenLDAP

!!! warning
    This is not a complete recipe - it's an **optional** component of the [Keycloak recipe](/recipes/keycloak/), but has been split into its own page to reduce complexity.

Keycloak gets really sexy when you integrate it into your [OpenLDAP](/recipes/openldap/) stack (_also, it's great not to have to play with ugly LDAP tree UIs_). Note that OpenLDAP integration is **not necessary** if you want to use Keycloak with [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/) - all you need for that is [local users][keycloak], and an [OIDC client](/recipes/keycloak/setup-oidc-provider/).

## Ingredients

!!! Summary
    Existing:

    * [X] [Keycloak](/recipes/keycloak/) recipe deployed successfully
  
    New:
    
    * [ ] An [OpenLDAP server](/recipes/openldap/) (*assuming you want to authenticate against it*)

## Preparation

You'll need to have completed the [OpenLDAP](/recipes/openldap/) recipe

You start in the "Master" realm - but mouseover the realm name, to a dropdown box allowing you add an new realm:

### Create Realm

![Keycloak Add Realm Screenshot](/images/sso-stack-keycloak-1.png){ loading=lazy }

Enter a name for your new realm, and click "_Create_":

![Keycloak Add Realm Screenshot](/images/sso-stack-keycloak-2.png){ loading=lazy }

### Setup User Federation

Once in the desired realm, click on **User Federation**, and click **Add Provider**. On the next page ("_Required Settings_"), set the following:

* **Edit Mode** : Writeable
* **Vendor** : Other
* **Connection URL** : ldap://openldap
* **Users DN** : ou=People,<your base DN\>
* **Authentication Type** : simple
* **Bind DN** : cn=admin,<your base DN\>
* **Bind Credential** : <your chosen admin password\>

Save your changes, and then navigate back to "User Federation" > Your LDAP name > Mappers:

![Keycloak Add Realm Screenshot](/images/sso-stack-keycloak-3.png){ loading=lazy }

For each of the following mappers, click the name, and set the "_Read Only_" flag to "_Off_" (_this enables 2-way sync between Keycloak and OpenLDAP_)

* last name
* username
* email
* first name

![Keycloak Add Realm Screenshot](/images/sso-stack-keycloak-4.png){ loading=lazy }

## Summary

We've setup a new realm in Keycloak, and configured read-write federation to an [OpenLDAP](/recipes/openldap/) backend. We can now manage our LDAP users using either [Keycloak][keycloak] [^1] or LDAP directly, and we can protect vulnerable services using [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/).

!!! Summary
    Created:

    * [X] Keycloak realm in read-write federation with [OpenLDAP](/recipes/openldap/) directory

[^1]: A much nicer experience IMO!

--8<-- "recipe-footer.md"
