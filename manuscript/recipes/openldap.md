# OpenLDAP

LDAP is probably the most ubiquitous authentication backend, before the current era of "[stupid social sign-ons](https://www.usatoday.com/story/tech/columnist/2018/10/23/how-separate-your-social-networks-your-regular-sites/1687763002/)". Many of the recipes featured in the cookbook (_[NextCloud](/recipes/nextcloud/), [Kanboard](/recipes/kanboard/), [Gitlab](/recipes/gitlab/), etc_) offer LDAP integration.

## Big deal, who cares?

If you're the only user of your tools, it probably doesn't bother you _too_ much to setup new user accounts for every tool. As soon as you start sharing tools with collaborators (_think 10 staff using NextCloud_), you suddenly feel the pain of managing a growing collection of local user accounts per-service.

Enter OpenLDAP - the most crusty, PITA, fiddly platform to setup (_yes, I'm a little bitter, [dynamic configuration backend](https://linux.die.net/man/5/slapd-config)!_), but hugely useful for one job - a Lightweight Protocol for managing a Directory used for Access (_see what I did [there](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)?_)

The nice thing about OpenLDAP is, like MySQL, once you've setup the server, you probably never have to interact directly with it. There are many tools which will let you interact with your LDAP database via a(n ugly) UI.

This recipe combines the raw power of OpenLDAP with the flexibility and featureset of LDAP Account Manager.

![OpenLDAP Screenshot](../images/openldap.jpeg)

## What's the takeaway?

What you'll end up with is a directory structure which will allow integration with popular tools (_[NextCloud](/recipes/nextcloud/), [Kanboard](/recipes/kanboard/), [Gitlab](/recipes/gitlab/), etc_), as well as with KeyCloak (_an upcoming recipe_), for **true** SSO.

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/openldap:

```
mkdir /var/data/openldap/openldap
mkdir /var/data/runtime/openldap/
```

!!! note "Why 2 directories?"
    For rationale, see my [data layout explanation](/reference/data_layout/)

### Prepare environment

Create /var/data/openldap/openldap.env, and populate with the following variables, customized for your own domain structure. Take care with LDAP_DOMAIN, this is core to your directory structure, and can't easily be changed later.

```
LDAP_DOMAIN=batcave.gotham
LDAP_ORGANISATION=BatCave Inc
LDAP_ADMIN_PASSWORD=supermansucks
LDAP_TLS=false

# Use these if you plan to protect the LDAP Account Manager webUI with an oauth_proxy
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

!!! note
    I use an [OAuth proxy](/reference/oauth_proxy/) to protect access to the web UI, when the sensitivity of the protected data (i.e. my authentication store) warrants it, or if I don't necessarily trust the security of the webUI.

Create ```authenticated-emails.txt```, and populate with the email addresses (_matched to GitHub user accounts, in my case_) to which you want grant access, using OAuth2.

### Create config.cfg

The Dockerized version of LDAP Account Manager is a little fiddly. In order to maintain a config file which persists across container restarts, we need to present the container with a copy of /var/www/html/config/lam.conf, tweaked for our own requirements.

Create ```/var/data/openldap/lam/config/config.cfg``` as follows:

???+ note "Much scroll, very text. Click here to collapse it for better readability"

    ```
    # password to add/delete/rename configuration profiles (default: lam)
    password: {SSHA}D6AaX93kPmck9wAxNlq3GF93S7A= R7gkjQ==

    # default profile, without ".conf"
    default: batcave

    # log level
    logLevel: 4

    # log destination
    logDestination: SYSLOG

    # session timeout in minutes
    sessionTimeout: 30

    # list of hosts which may access LAM
    allowedHosts:

    # list of hosts which may access LAM Pro self service
    allowedHostsSelfService:

    # encrypt session data
    encryptSession: true

    # Password: minimum password length
    passwordMinLength: 0

    # Password: minimum uppercase characters
    passwordMinUpper: 0

    # Password: minimum lowercase characters
    passwordMinLower: 0

    # Password: minimum numeric characters
    passwordMinNumeric: 0

    # Password: minimum symbolic characters
    passwordMinSymbol: 0

    # Password: minimum character classes (0-4)
    passwordMinClasses: 0

    # Password: checked rules
    checkedRulesCount: -1

    # Password: must not contain part of user name
    passwordMustNotContain3Chars: false

    # Password: must not contain user name
    passwordMustNotContainUser: false

    # Email format (default/unix)
    mailEOL: default

    # PHP error reporting (default/system)
    errorReporting: default

    # License
    license:
    ```

### Create <profile\>.cfg

While config.cfg (_above_) defines application-level configuration, <profile\>.cfg is used to configure "domain-specific" configuration. You probably only need a single profile, but LAM could theoretically be used to administer several totally unrelated LDAP servers, ergo the concept of "profiles".

Create yours profile (_you chose a default profile in config.cfg above, remember?_) by creating ```/var/data/openldap/lam/config/<profile>.conf```, as follows:

???+ note "Much scroll, very text. Click here to collapse it for better readability"

    ```
    # LDAP Account Manager configuration
    #
    # Please do not modify this file manually. The configuration can be done completely by the LAM GUI.
    #
    ###################################################################################################

    # server address (e.g. ldap://localhost:389 or ldaps://localhost:636)
    ServerURL: ldap://openldap:389

    # list of users who are allowed to use LDAP Account Manager
    # names have to be separated by semicolons
    # e.g. admins: cn=admin,dc=yourdomain,dc=org;cn=root,dc=yourdomain,dc=org
    Admins: cn=admin,dc=batcave,dc=gotham

    # password to change these preferences via webfrontend (default: lam)
    Passwd: {SSHA}h39N9+gg/Qf1K/986VkKrjWlkcI= S/IAUQ==

    # suffix of tree view
    # e.g. dc=yourdomain,dc=org
    treesuffix: dc=batcave,dc=gotham

    # default language (a line from config/language)
    defaultLanguage: en_GB.utf8

    # Path to external Script
    scriptPath:

    # Server of external Script
    scriptServer:

    # Access rights for home directories
    scriptRights: 750

    # Number of minutes LAM caches LDAP searches.
    cachetimeout: 5

    # LDAP search limit.
    searchLimit: 0

    # Module settings

    modules: posixAccount_user_minUID: 10000
    modules: posixAccount_user_maxUID: 30000
    modules: posixAccount_host_minMachine: 50000
    modules: posixAccount_host_maxMachine: 60000
    modules: posixGroup_group_minGID: 10000
    modules: posixGroup_group_maxGID: 20000
    modules: posixGroup_pwdHash: SSHA
    modules: posixAccount_pwdHash: SSHA

    # List of active account types.
    activeTypes: user,group


    types: suffix_user: ou=People,dc=batcave,dc=gotham
    types: attr_user: #uid;#givenName;#sn;#uidNumber;#gidNumber
    types: modules_user: inetOrgPerson,posixAccount,shadowAccount

    types: suffix_group: ou=Groups,dc=batcave,dc=gotham
    types: attr_group: #cn;#gidNumber;#memberUID;#description
    types: modules_group: posixGroup

    # Password mail subject
    lamProMailSubject: Your password was reset

    # Password mail text
    lamProMailText: Dear @@givenName@@ @@sn@@,+::++::+your password was reset to: @@newPassword@@+::++::++::+Best regards+::++::+deskside support+::+



    serverDisplayName:


    # enable TLS encryption
    useTLS: no


    # follow referrals
    followReferrals: false


    # paged results
    pagedResults: false

    referentialIntegrityOverlay: false


    # time zone
    timeZone: Europe/London

    scriptUserName:

    scriptSSHKey:

    scriptSSHKeyPassword:


    # Access level for this profile.
    accessLevel: 100


    # Login method.
    loginMethod: list


    # Search suffix for LAM login.
    loginSearchSuffix: dc=batcave,dc=gotham


    # Search filter for LAM login.
    loginSearchFilter: uid=%USER%


    # Bind DN for login search.
    loginSearchDN:


    # Bind password for login search.
    loginSearchPassword:


    # HTTP authentication for LAM login.
    httpAuthentication: false


    # Password mail from
    lamProMailFrom:


    # Password mail reply-to
    lamProMailReplyTo:


    # Password mail is HTML
    lamProMailIsHTML: false


    # Allow alternate address
    lamProMailAllowAlternateAddress: true

    jobsBindPassword:

    jobsBindUser:

    jobsDatabase:

    jobsDBHost:

    jobsDBPort:

    jobsDBUser:

    jobsDBPassword:

    jobsDBName:

    jobToken: 190339140545

    pwdResetAllowSpecificPassword: true

    pwdResetAllowScreenPassword: true

    pwdResetForcePasswordChange: true

    pwdResetDefaultPasswordOutput: 2

    twoFactorAuthentication: none

    twoFactorAuthenticationURL: https://localhost

    twoFactorAuthenticationInsecure:

    twoFactorAuthenticationLabel:

    twoFactorAuthenticationOptional:

    twoFactorAuthenticationCaption:
    tools: tool_hide_toolOUEditor: false
    tools: tool_hide_toolProfileEditor: false
    tools: tool_hide_toolSchemaBrowser: false
    tools: tool_hide_toolServerInformation: false
    tools: tool_hide_toolTests: false
    tools: tool_hide_toolPDFEditor: false
    tools: tool_hide_toolFileUpload: false
    tools: tool_hide_toolMultiEdit: false
    ```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this, at  (```/var/data/config/openldap/openldap.yml```)

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  openldap:
    image: osixia/openldap
    env_file: /var/data/config/openldap/openldap.env
    networks:
    - traefik_public
    - auth_internal
    volumes:
    - /var/data/runtime/openldap/:/var/lib/ldap
    - /var/data/openldap/openldap/:/etc/ldap/slapd.d

  lam:
    image: jacksgt/ldap-account-manager
    networks:
    - auth_internal
    volumes:
    - /var/data/openldap/lam/config/config.cfg:/var/www/html/config/config.cfg
    - /var/data/openldap/lam/config/batcave.conf:/var/www/html/config/batcave.conf

  lam-proxy:
    image: funkypenguin/oauth2_proxy
    env_file: /var/data/config/openldap/openldap.env
    networks:
      - traefik_public
      - auth_internal
    deploy:
      labels:
        - traefik.frontend.rule=Host:lam.batcave.com
        - traefik.docker.network=traefik_public
        - traefik.port=4180
    command: |
      -cookie-secure=false
      -upstream=http://lam:8080
      -redirect-url=https://lam.batcave.com
      -http-address=http://0.0.0.0:4180
      -email-domain=batcave.com
      -provider=github


networks:
  # Used to expose lam-proxy to external access, and openldap to keycloak
  traefik_public:
    external: true

  # Used to expose openldap to other apps which want to talk to LDAP, including LAM
  auth_internal:
    external: true    
```

!!! warning
    **Normally**, we set unique static subnets for every stack you deploy, and put the non-public facing components (like databases) in an dedicated <stack\>_internal network. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.

    However, you're likely to want to use OpenLdap with KeyCloak, whose JBOSS startup script assumes a single interface, and will crash in a ball of 🔥 if you try to assign multiple interfaces to the container.

    Since we're going to want KeyCloak to be able to talk to OpenLDAP, we have no choice but to leave the OpenLDAP container on the "traefik_public" network. We can, however, create **another** overlay network (_auth_internal, see below_), add it to the openldap container, and use it to provide OpenLDAP access to our other stacks.

Create **another** stack config file (```/var/data/config/openldap/auth.yml```) containing just the auth_internal network, and a dummy container:

```
version: "3.2"

# What is this?
#
# This stack exists solely to deploy the auth_internal overlay network, so that
# other stacks (including keycloak and openldap) can attach to it

services:
  scratch:
    image: scratch
    deploy:
      replicas: 0
    networks:
      - internal

networks:
  internal:
    driver: overlay
    attachable: true
    ipam:
      config:
        - subnet: 172.16.39.0/24
```




## Serving

### Launch OpenLDAP stack

Create the auth_internal overlay network, by running ```docker stack deploy auth -c /var/data/config/openldap/auth.yml```, then launch the OpenLDAP stack by running ```docker stack deploy openldap -c /var/data/config/openldap/openldap.yml```

Log into your new LAM instance at https://**YOUR-FQDN**.

On first login, you'll be prompted to create the "_ou=People_" and "_ou=Group_" elements. Proceed to create these.

You've now setup your OpenLDAP directory structure, and your administration interface, and hopefully won't have to interact with the "special" LDAP Account Manager interface much again!

Create your users using the "**New User**" button.

[^1]: [The KeyCloak](/recipes/keycloak/authenticate-against-openldap/) recipe illustrates how to integrate KeyCloak with your LDAP directory, giving you a cleaner interface to manage users, and a raft of SSO / OAuth features.

--8<-- "recipe-footer.md"