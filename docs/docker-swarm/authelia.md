---
title: Using Authelia to secure services in Docker
description: Authelia is an open-source authentication and authorization server providing 2-factor authentication and single sign-on (SSO) for your applications via a web portal.
---

# Authelia in Docker Swarm

[Authelia](https://github.com/authelia/authelia) is an open-source authentication and authorization server providing 2-factor authentication and single sign-on (SSO) for your applications via a web portal. Like [Traefik Forward Auth][tfa], Authelia acts as a companion of reverse proxies like Nginx, [Traefik](/docker-swarm/traefik/), or HAProxy to let them know whether queries should pass through. Unauthenticated users are redirected to Authelia Sign-in portal instead. Authelia is a popular alternative to a heavyweight such as [KeyCloak][keycloak].

![Authelia Screenshot](/images/authelia.png){ loading=lazy }

Features include

* Multiple two-factor methods such as
  * [Physical Security Key](https://www.authelia.com/docs/features/2fa/security-key) (Yubikey)
  * OTP using Google Authenticator
  * Mobile Notifications
* Lockout users after too many failed login attempts
* Highly Customizable Access Control using rules to match criteria such as subdomain, username, groups the user is in, and Network
* Authelia [Community](https://discord.authelia.com/) Support
* Full list of features can be viewed [here](https://www.authelia.com/)

## Authelia requirements

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik/) configured per design

    New:

    * [ ] DNS entry for your auth host (*"authelia.yourdomain.com" is a good choice*), pointed to your [keepalived](/docker-swarm/keepalived/) IP

### Setup data locations

First, we create a directory to hold the data which authelia will serve:

```bash
mkdir /var/data/config/authelia
```

### Create Authelia config file

Authelia configurations are defined in `/var/data/config/authelia/configuration.yml`. Some are required and some are optional. The following is a variation of the default example config file. Optional configuration settings can be viewed on in [Authelia's documentation](https://www.authelia.com/configuration/prologue/introduction/)

!!! warning
    Your variables may vary significantly from what's illustrated below, and it's best to read up and understand exactly what each option does.

```yaml title="/var/data/config/authelia/configuration.yml"
###############################################################
#                   Authelia configuration                    #
###############################################################

server:
  host: 0.0.0.0
  port: 9091

log:
  level: warn

# This secret can also be set using the env variables AUTHELIA_JWT_SECRET_FILE
# I used this site to generate the secret: https://www.grc.com/passwords.htm
jwt_secret: SECRET_GOES_HERE

# https://docs.authelia.com/configuration/miscellaneous.html#default-redirection-url
default_redirection_url: https://authelia.example.com

totp:
  issuer: authelia.example.com
  period: 30
  skew: 1

authentication_backend:
  file:
    path: /config/users_database.yml
    # customize passwords based on https://docs.authelia.com/configuration/authentication/file.html
    password:
      algorithm: argon2id
      iterations: 1
      salt_length: 16
      parallelism: 8
      memory: 1024 # blocks this much of the RAM. Tune this.

# https://docs.authelia.com/configuration/access-control.html
access_control:
  default_policy: one_factor
  rules:
    - domain: "bitwarden.example.com"
      policy: two_factor

    - domain: "whoami-authelia-2fa.example.com"
      policy: two_factor      

    - domain: "*.example.com" # (1)!
      policy: one_factor


session:
  name: authelia_session
  # This secret can also be set using the env variables AUTHELIA_SESSION_SECRET_FILE
  # Used a different secret, but the same site as jwt_secret above.
  secret: SECRET_GOES_HERE
  expiration: 3600 # 1 hour
  inactivity: 300 # 5 minutes
  domain: example.com # Should match whatever your root protected domain is

regulation:
  max_retries: 3
  find_time: 120
  ban_time: 300

storage:
  encryption_key: SECRET_GOES_HERE_20_CHARACTERS_OR_LONGER
  local:
    path: /config/db.sqlite3


notifier:
  # smtp:
  #   username: SMTP_USERNAME
  #   # This secret can also be set using the env variables AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE
  #   # password: # use docker secret file instead AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE
  #   host: SMTP_HOST
  #   port: 587 #465
  #   sender: batman@example.com # customize for your setup

  # For testing purpose, notifications can be sent in a file. Be sure map the volume in docker-compose.
  filesystem:
    filename: /config/notification.txt
```

1. The wildcard rule must go last, since the first rule to match the request, wins

### Create Authelia user Accounts

Create `/var/data/config/authelia/users_database.yml` this will be where we can create user accounts and give them groups

```yaml title="/var/data/config/authelia/users_database.yml"
# To create a hashed password you can run the following command:
# `docker run authelia/authelia:latest authelia hash-password YOUR_PASSWORD``
users:
  batman: # each new user should be defined in a dictionary like this
    displayname: "Batman"
    # replace this with your hashed password. This one, for the purposes of testing, is "password"
    password: "$argon2id$v=19$m=65536,t=3,p=4$cW1adlh3UjhIRE9zSmZyZw$xA4S2X8BjE7LVb4NndJCZnoyHgON5w3FopO4vw5AQxE"
    email: batman@example.com
    groups:
      - admins
      - dev
```

To create a hashed password you can run the following command
`docker run authelia/authelia:latest authelia hash-password YOUR_PASSWORD`

### Authelia Docker Swarm config

Create a docker swarm config file in docker-compose syntax (v3), something like this example:

--8<-- "premix-cta.md"

```yaml title="/var/data/config/authelia/authelia.yml"
version: "3.2"

services:
  authelia:
    image: authelia/authelia
    volumes:
      - /var/data/config/authelia:/config
    networks:
      - traefik_public
    deploy:
      labels:
        # traefik common
        - traefik.enable=true
        - traefik.docker.network=traefik_public

        # traefikv1
        - traefik.frontend.rule=Host:authelia.example.com
        - traefik.port=80
        - 'traefik.frontend.auth.forward.address=http://authelia:9091/api/verify?rd=https://authelia.example.com/'
        - 'traefik.frontend.auth.forward.trustForwardHeader=true'
        - 'traefik.frontend.auth.forward.authResponseHeaders=Remote-User,Remote-Groups,Remote-Name,Remote-Email'

        # traefikv2
        - "traefik.http.routers.authelia.rule=Host(`authelia.example.com`)"
        - "traefik.http.routers.authelia.entrypoints=https"
        - "traefik.http.services.authelia.loadbalancer.server.port=9091"
        
  whoami-1fa: # (1)!
    image: containous/whoami
    networks:
      - traefik_public
    deploy:
      labels:
        # traefik
        - "traefik.enable=true"
        - "traefik.docker.network=traefik_public"

        # traefikv1
        - "traefik.frontend.rule=Host:whoami-authelia-1fa.example.com"
        - traefik.port=80
        - 'traefik.frontend.auth.forward.address=http://authelia:9091/api/verify?rd=https://authelia.example.com/'
        - 'traefik.frontend.auth.forward.trustForwardHeader=true'
        - 'traefik.frontend.auth.forward.authResponseHeaders=Remote-User,Remote-Groups,Remote-Name,Remote-Email'

        # traefikv2
        - "traefik.http.routers.whoami-authelia-1fa.rule=Host(`whoami-authelia-1fa.example.com`)"
        - "traefik.http.routers.whoami-authelia-1fa.entrypoints=https"
        - "traefik.http.routers.whoami-authelia-1fa.middlewares=authelia"
        - "traefik.http.services.whoami-authelia-1fa.loadbalancer.server.port=80"


      whoami-2fa: # (2)!
        image: containous/whoami
        networks:
          - traefik_public
        deploy:
          labels:
            # traefik
            - "traefik.enable=true"
            - "traefik.docker.network=traefik_public"

            # traefikv1
            - "traefik.frontend.rule=Host:whoami-authelia-2fa.example.com"
            - traefik.port=80
            - 'traefik.frontend.auth.forward.address=http://authelia:9091/api/verify?rd=https://authelia.example.com/'
            - 'traefik.frontend.auth.forward.trustForwardHeader=true'
            - 'traefik.frontend.auth.forward.authResponseHeaders=Remote-User,Remote-Groups,Remote-Name,Remote-Email'

            # traefikv2
            - "traefik.http.routers.whoami-authelia-2fa.rule=Host(`whoami-authelia-2fa.example.com`)"
            - "traefik.http.routers.whoami-authelia-2fa.entrypoints=https"
            - "traefik.http.routers.whoami-authelia-2fa.middlewares=authelia"
            - "traefik.http.services.whoami-authelia-2fa.loadbalancer.server.port=80"

    networks:
      traefik_public:
        external: true 
```

1. Optionally used to test 1FA authentication
2. Optionally used to test 2FA authentication

!!! question "Why not just use Traefik Forward Auth?"
    While [Traefik Forward Auth][tfa] is a very lightweight, minimal authentication layer, which provides OIDC-based authentication, Authelia provides more features such as multiple methods of authentication (*Hardware, OTP, Email*), advanced rules, and push notifications.

## Run Authelia

Launch the Authelia stack by running ```docker stack deploy authelia -c <path -to-docker-compose.yml>```

### Test Authelia

To test the service works successfully, try logging into Authelia itself first, as a user whose password you've setup in `/var/data/config/authelia/users_database.yml`.

You'll notice that upon successful login, you're requested to setup 2FA. If (*like me!*) you didn't configure an SMTP server, you can still setup 2FA (*TOTP or webauthn*), and the setup link email instructions should be found in `/var/data/config/authelia/notifications.txt`

Now you're ready to test 1FA and 2FA auth, against the two "whoami" services defined in the docker-compose file.

Try to access each in turn, and confirm that you're *not* prompted for 2FA on whoami-authelia-1fa, but you *are* prompted for 2FA on whoami-authelia-2fa! :thumbsup:

## Summary

What have we achieved? By adding a simple label to any service, we can secure any service behind our Authelia, with minimal processing / handling overhead, and benefit from the 1FA/2FA multi-layered features provided by Autheila.

!!! summary "Summary"
    Created:

    * [X] Authelia configured and available to provide a layer of authentication to other services deployed in the stack

### Authelia vs Keycloak

[KeyCloak][keycloak] is the "big daddy" of self-hosted authentication platforms - it has a beautiful GUI, and a very advanced and mature featureset. Like Authelia, KeyCloak can [use an LDAP server](/recipes/keycloak/authenticate-against-openldap/) as a backend, but *unlike* Authelia, KeyCloak allows for 2-way sync between that LDAP backend, meaning KeyCloak can be used to *create* and *update* the LDAP entries (*Authelia's is just a one-way LDAP lookup - you'll need another tool to actually administer your LDAP database*).

[^1]: The initial inclusion of Authelia was due to the efforts of @bencey in Discord (Thanks Ben!)

--8<-- "recipe-footer.md"
