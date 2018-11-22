# OpenLDAP with LAM

!!! warning
    While this could stand on its own as a standalone recipe, it's a component of the [sso-stack](/recipes/sso-stack/) "_uber-recipe_", and is written in the expectation that the entire SSO stack is being deployed.

![OpenLDAP Screenshot](../images/openldap.png)

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik_public) configured per design
3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/openldap:

```
mkdir /var/data/openldap/openldap
mkdir /var/data/runtime/openldap/
```

### Prepare environment

Create /var/data/openldap/openldap.env, and populate with the following variables, customized for your own domain struction. Take care with LDAP_DOMAIN, this is core to the rest of the [sso-stack](/recipes/sso-stack/), and can't easily be changed later.
```
LDAP_DOMAIN=batcave.gotham
LDAP_ORGANISATION=BatCave Inc
LDAP_ADMIN_PASSWORD=supermansucks
LDAP_TLS=false

# Setup for github
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

Create ```authenticated-emails.txt```, and populate with the email addresses (matched to GitHub user accounts, in my case) which you want to grant access, using OAuth2.

### Create config.cfg

```

# password to add/delete/rename configuration profiles (default: lam)
password: {SSHA}54haBZN/kfgNVJ+W3YJrI2dCic4= iCXkNA==

# default profile, without ".conf"
default: observeglobal

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

### Create <profile>.cfg

```
# LDAP Account Manager configuration
#
# Please do not modify this file manually. The configuration can be done completely by the LAM GUI.
#
###################################################################################################

# server address (e.g. ldap://localhost:389 or ldaps://localhost:636)
ServerURL: ldap://openldap:389

# list of users who are allowed to use LDAP Account Manager
# names have to be seperated by semicolons
# e.g. admins: cn=admin,dc=yourdomain,dc=org;cn=root,dc=yourdomain,dc=org
Admins: cn=admin,dc=observe,dc=global

# password to change these preferences via webfrontend (default: lam)
Passwd: {SSHA}h39N9+gg/Qf1K/986VkKrjWlkcI= S/IAUQ==

# suffix of tree view
# e.g. dc=yourdomain,dc=org
treesuffix: dc=observe,dc=global

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


types: suffix_user: ou=People,dc=observe,dc=global
types: attr_user: #uid;#givenName;#sn;#uidNumber;#gidNumber
types: modules_user: inetOrgPerson,posixAccount,shadowAccount

types: suffix_group: ou=Groups,dc=observe,dc=global
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
loginSearchSuffix: dc=yourdomain,dc=org


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

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍
```
version: '3'

services:
  openldap:
    image: osixia/openldap
    env_file: /var/data/config/openldap/openldap.env
    networks:
    - traefik_public
    volumes:
    - /var/data/openldap/openldap/:/var/lib/ldap
    - /var/data/runtime/openldap/:/etc/ldap/slapd.d

  lam:
    image: jacksgt/ldap-account-manager
    networks:
    - traefik_public
    #volumes:
    #- /var/data/openldap/lam/config/lam.conf:/var/www/html/config/lam.conf


  proxy:
    image: funkypenguin/oauth2_proxy
    env_file: /var/data/config/openldap/openldap.env
    networks:
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:lam.example.com
        - traefik.port=4180
    volumes:
      - /var/data/config/openldap/authenticated-emails.txt:/authenticated-emails.txt
    command: |
      -cookie-secure=false
      -upstream=http://lam:8080
      -redirect-url=https://lam.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github
      -authenticated-emails-file=/authenticated-emails.txt


networks:
  traefik_public:
    external: true
```

## Serving

### Launch OpenLDAP stack

Launch the OpenLDAP stack by running ```docker stack deploy openldap -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**. You'll hit the LDAP Account Manager login page, which will look like this:

![LAM Landing Page Screenshot](/images/sso-stack-lam-1.png)

Click on "LAM Configuration" to add a profile.

![LAM Edit Profiles Screenshot](/images/sso-stack-lam-2.png)

Enter a profile name, and a profile password (twice). Leave the template at "_unix_":

![LAM Edit Profiles Screenshot](/images/sso-stack-lam-3.png)

When prompted to save your new profile, enter the "master password" ("lam")

You've created a "profile". Now to configure your profile... Start with "Server Settings", and change your **server address** to ```ldap://openldap:389```, and your **tree suffix** to the base DN you setup in the openldap.env file (above).

![LAM Edit Profiles Screenshot](/images/sso-stack-lam-4.png)

Under **Security Settings**, alter the list of valid users to "**cn=admin\<your-base-dn\>**"

![LAM Edit Profiles Screenshot](/images/sso-stack-lam-5.png)

After you save, you'll be redirected to the profile login page, where you'll need to enter the profile details and password you create above.

Once logged in, click on the "**Account Types"** tab...

![LAM Edit Profiles Screenshot](/images/sso-stack-lam-6.png)

And for both "_Users_" and "_Groups_", edit the "LDAP Suffix" to match your chosen Base DN, and save your changes:

![LAM Edit Profiles Screenshot](/images/sso-stack-lam-7.png)

After saving changes to your LAM profile, you'll be redirected to the LAM admin page. Enter your credentials (default admin/admin) to login. On first login, you'll be prompted to create the "ou=People" and "ou=Group" elements. Proceed to create these.

You've now setup your OpenLDAP directory structure, and hopefully won't have to interact with the "special" LDAP Account Manager interface much again!

Proceed to setting up [KeyCloak](/recipes/sso-stack/keycloak/)...

## Chef's Notes

1. What's not yet documented here is how to make the LAM "profile" configuration persistent. I.e., after each container reload, it's currently necessary to repeat the steps above.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
