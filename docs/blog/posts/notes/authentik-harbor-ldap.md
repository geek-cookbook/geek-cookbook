---
title: Authenticate Harbor with Authentik LDAP outpost
date: 2023-11-06
tags:
  - authentik
categories:
  - note
description: How to authenticate Harbor with Authentik's LDAP outposts
---

[authentik][k8s/authentik] does an excellent job as an authentication provider using modern protocols like OIDC. Some applications (*like [Jellyfin][jellyfin] or [Harbor](https://goharbor.io/)*) won't support OIDC, but can be configured to use LDAP for authentication.

I recently migrated a Harbor instance from an [OpenLDAP] authentication backend to Authentik's LDAP outpost, and struggled a little with the configuration.

Now that it's working, I thought I'd document it here so that I don't forget!

<!-- more -->

Two critical issues affected the Harbor / LDAP configuration:

1. Harbor won't let you login if it gets more than one result when looking up your user in LDAP[^1]
2. Authentik **will** create "virtual" user groups matching your username, for POSIX compliance.

> A virtual group is also created for each user, they have the same fields as groups but have an additional objectClass: goauthentik.io/ldap/virtual-group. The virtual groups gidNumber is equal to the uidNumber of the user - (https://goauthentik.io/docs/providers/ldap/)

What this means for your config is that you actually can't use your base DN for the user lookup, because you'll get a match from `ou=users` as well as a match from `ou=groups`. You'll need to ensure that the base DN for user searches includes `ou=users`.

Here's my complete, working configuration:

![](/images/harbor-with-authentik-ldap-auth.png)

!!! question "What's the LDAP filter?"
    The LDAP filter (truncated above) is `(&(objectclass=inetOrgPerson)(memberof=cn=*-harbor,ou=groups,dc=elpenguino,dc=net))`, which matches any member of any group **ending** in `-harbor`, so I could create groups like `admin-harbor`, `read-harbor`, `ops-harbor`, etc.

[^1]: This error is only visible in the harbor-core pod logs!

--8<-- "blog-footer.md"