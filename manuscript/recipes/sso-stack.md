hero: SSO for all your stack elements 🎁

# SSO Stack

Most of the recipes in the cookbook are stand-alone - you can deploy and use them in isolation. I was approached recently by an anonymous sponsor, who needed a stack which would allow the combination of several collaborative tools, in a manner which permits "single signon (SSO)". I.e., the goal of the design was that a user would be provisioned _once_, and thereafter have transparent access to multiple separate applications.

The SSO Stack "uber-recipe" is the result of this design.

![SSO Stark Screenshot](../images/sso-stack.png)

This recipe presents a method to combine multiple tools into a single swarm deployment, and make them available securely.

## Menu

Tools included in the SSO stack are:

* **[OpenLDAP](https://www.openldap.org/)** : Provides Authentication backend
* **[LDAP Account Manager ](https://www.ldap-account-manager.org)** (LAM) : A Web_UI to manage LDAP accounts
* **[KeyCloak](https://www.keycloak.org/)** is an open source identity and access management solution, providing SSO and 2FA capabilities backed into authentication provides (like OpenLDAP)
* **[docker-mailserver](https://github.com/tomav/docker-mailserver)** : A fullstack, simple mail platform including SMTP, IMAPS, and spam filtering components
* **[RainLoop](https://www.rainloop.net/)** : A fast, modern webmail client
* **[GitLab](https://gitlab.org)** : A powerful collaborative git-based developmenet platform
* **[NextCloud](https://www.nextcloud.org)** : A file share and communication platform

This is a complex recipe, and should be deployed in a sequential manner (_i.e. you need OpenLDAP with LDAP Account Manager, to enable KeyCloak, in order to get SSO available for NextCloud, etc.._)

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. Access to NZB indexers and Usenet servers
4. DNS entries configured for each of the NZB tools in this recipe that you want to use

## Preparation

Now work your way through the list of tools below, adding whichever tools your want to use, and finishing with the **end** section:

* [OpenLDAP](/recipes/sso-stack/openldap.md)

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
