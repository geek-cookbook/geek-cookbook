---
date: 2023-10-31
categories:
  - CHANGELOG
tags:
  - authentik
links:
  - Authentik on Kubernetes: recipes/kubernetes/authentik.md
description: New Recipe Added - authentik - Flexible Identity Provider, running on Kubernetes
title: Added / authentik on Kubernetes
image: /images/authentik.png
---

# Added recipe for authentik (Kubernetes)

Too young (*and sensible!*) for [OpenLDAP][openldap] :t_rex:, and don't need the java-based headaches of [KeyCloak][keycloak]?

Up your IDP game with [authentik][k8s/authentik], your own "flexible and versatile" Identity Provider, in your Kubernetes Cluster.

<!-- more -->

![Screenshot of authentik]({{ page.meta.image }}){ loading=lazy }

authentik is an open-source Identity Provider, focused on flexibility and versatility. With authentik, site administrators, application developers, and security engineers have a dependable and secure solution for authentication in almost any type of environment. There are robust recovery actions available for the users and applications, including user profile and password management. You can quickly edit, deactivate, or even impersonate a user profile, and set a new password for new users or reset an existing password.

You can use authentik in an existing environment to add support for new protocols, so introducing authentik to your current tech stack doesn't present re-architecting challenges. We already support all of the major providers, such as OAuth2, SAML, LDAP, and SCIM, so you can pick the protocol that you need for each application.

See the [recipe][k8s/authentik] for more!

--8<-- "common-links.md"
