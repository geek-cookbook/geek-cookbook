# Create KeyCloak Users

!!! warning
This is not a complete recipe - it's an optional component of the [Keycloak recipe](/recipes/keycloak/), but has been split into its own page to reduce complexity.

Unless you plan to authenticate against an outside provider (_[OpenLDAP](/recipes/keycloak/authenticate-against-openldap/), below, for example_), you'll want to create some local users..

## Ingredients

!!! Summary
Existing:

    * [X] [KeyCloak](/recipes/keycloak/) recipe deployed successfully

### Create User

Within the "Master" realm (_no need for more realms yet_), navigate to **Manage** -> **Users**, and then click **Add User** at the top right:

![Navigating to the add user interface in Keycloak](/images/keycloak-add-user-1.png)

Populate your new user's username (it's the only mandatory field)

![Populating a username in the add user interface in Keycloak](/images/keycloak-add-user-2.png)

### Set User Credentials

Once your user is created, to set their password, click on the "**Credentials**" tab, and procede to reset it. Set the password to non-temporary, unless you like extra work!

![Resetting a user's password in Keycloak](/images/keycloak-add-user-3.png)

## Summary

We've setup users in KeyCloak, which we can now use to authenticate to KeyCloak, when it's used as an [OIDC Provider](/recipes/keycloak/setup-oidc-provider/), potentially to secure vulnerable services using [Traefik Forward Auth](/ha-docker-swarm/traefik-forward-auth/).

!!! Summary
    Created:

    * [X] Username / password to authenticate against [KeyCloak](/recipes/keycloak/)

--8<-- "recipe-footer.md"