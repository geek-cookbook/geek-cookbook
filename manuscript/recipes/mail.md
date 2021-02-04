hero: Docker-mailserver - A recipe for a self-contained mailserver and friends ✉️

# Mail Server

Many of the recipes that follow require email access of some kind. It's  normally possible to use a hosted service such as SendGrid, or just a gmail account. If (like me) you'd like to self-host email for your stacks, then the following recipe provides a full-stack mail server running on the docker HA swarm.

Of value to me in choosing docker-mailserver were:

1. Automatically renews LetsEncrypt certificates
2. Creation of email accounts across multiple domains (i.e., the same container gives me mailbox wekan@wekan.example.com, and gitlab@gitlab.example.com)
3. The entire configuration is based on flat files, so there's no database or persistence to worry about

docker-mailserver doesn't include a webmail client, and one is not strictly needed. Rainloop can be added either as another service within the stack, or as a standalone service. Rainloop will be covered in a future recipe.

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. LetsEncrypt authorized email address for domain
3. Access to manage DNS records for domains

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/docker-mailserver:

```
cd /var/data
mkdir docker-mailserver
cd docker-mailserver
mkdir {maildata,mailstate,config,letsencrypt,rainloop}
```

### Get LetsEncrypt certificate

Decide on the FQDN to assign to your mailserver. You can service multiple domains from a single mailserver - i.e., bob@dev.example.com and daphne@prod.example.com can both be served by **mail.example.com**.

The docker-mailserver container can _renew_ our LetsEncrypt certs for us, but it can't generate them. To do this, we need to run certbot (from a container) to request the initial certs and create the appropriate directory structure.

In the example below, since I'm already using Traefik to manage the LE certs for my web platforms, I opted to use the DNS challenge to prove my ownership of the domain. The certbot client will prompt you to add a DNS record for domain verification.

```
docker run -ti --rm -v \
"$(pwd)"/letsencrypt:/etc/letsencrypt certbot/certbot \
--manual --preferred-challenges dns certonly \
-d mail.example.com
```

### Get setup.sh

docker-mailserver comes with a handy bash script for managing the stack (which is just really a wrapper around the container.) It'll make our setup easier, so download it into the root of your configuration/data directory, and make it executable:

```
curl -o setup.sh \
https://raw.githubusercontent.com/tomav/docker-mailserver/master/setup.sh \
chmod a+x ./setup.sh
```
### Create email accounts

For every email address required, run ```./setup.sh email add <email> <password>``` to create the account. The command returns no output.

You can run ```./setup.sh email list``` to confirm all of your addresses have been created.

### Create DKIM DNS entries

Run ```./setup.sh config dkim``` to create the necessary DKIM entries. The command returns no output.

Examine the keys created by opendkim to identify the DNS TXT records required:

```
for i in `find config/opendkim/keys/ -name mail.txt`; do \
echo $i; \
cat $i; \
done
```

You'll end up with something like this:

```
config/opendkim/keys/gitlab.example.com/mail.txt
mail._domainkey	IN	TXT	( "v=DKIM1; k=rsa; "
	  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCYuQqDg2ZG8ZOfI1PvarF1Gcr5cJnCR8BeCj5HYgeRohSrxKL5utPEF/AWAxXYwnKpgYN837fu74GfqsIuOhu70lPhGV+O2gFVgpXYWHELvIiTqqO0QgarIN63WE2gzE4s0FckfLrMuxMoXr882wuzuJhXywGxOavybmjpnNHhbQIDAQAB" )  ; ----- DKIM key mail for gitlab.example.com
[root@ds1 mail]#
```

Create the necessary DNS TXT entries for your domain(s). Note that although opendkim splits the record across two lines, the actual record should be concatenated on creation. I.e., the DNS TXT record above should read:

```
"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCYuQqDg2ZG8ZOfI1PvarF1Gcr5cJnCR8BeCj5HYgeRohSrxKL5utPEF/AWAxXYwnKpgYN837fu74GfqsIuOhu70lPhGV+O2gFVgpXYWHELvIiTqqO0QgarIN63WE2gzE4s0FckfLrMuxMoXr882wuzuJhXywGxOavybmjpnNHhbQIDAQAB"
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (_v3.2 - because we need to expose mail ports in "host mode"_), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3.2'

services:
  mail:
    image: tvial/docker-mailserver:latest
    ports:
      - target: 25
        published: 25
        protocol: tcp
        mode: host
      - target: 587
        published: 587
        protocol: tcp
        mode: host
      - target: 993
        published: 993
        protocol: tcp
        mode: host
      - target: 995
        published: 995
        protocol: tcp
        mode: host
    volumes:
      - /var/data/docker-mailserver/maildata:/var/mail
      - /var/data/docker-mailserver/mailstate:/var/mail-state
      - /var/data/docker-mailserver/config:/tmp/docker-mailserver
      - /var/data/docker-mailserver/letsencrypt:/etc/letsencrypt
    env_file: /var/data/docker-mailserver/docker-mailserver.env
    networks:
      - internal
    deploy:
      replicas: 1

	rainloop:
    image: hardware/rainloop
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:rainloop.example.com
        - traefik.docker.network=traefik_public
        - traefik.port=8888
    volumes:
      - /var/data/mailserver/rainloop:/rainloop/data

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.2.0/24
```

--8<-- "reference-networks.md"

A sample docker-mailserver.env file looks like this:

```
ENABLE_SPAMASSASSIN=1
ENABLE_CLAMAV=1
ENABLE_POSTGREY=1
ONE_DIR=1
OVERRIDE_HOSTNAME=mail.example.com
OVERRIDE_DOMAINNAME=mail.example.com
POSTMASTER_ADDRESS=admin@example.com
PERMIT_DOCKER=network
SSL_TYPE=letsencrypt
```


## Serving

### Launch mailserver

Launch the mail server stack by running ```docker stack deploy docker-mailserver -c <path-to-docker-mailserver.yml>```

[^1]: One of the elements of this design which I didn't appreciate at first is that since the config is entirely file-based, **setup.sh** can be run on any container host, provided it has the shared data mounted. This means that even though docker-mailserver was not designed with docker swarm in mind, it works perfectl with swarm. I.e., from any node, regardless of where the container is actually running, you're able to add/delete email addresses, view logs, etc.

[^2]: If you're using sieve with Rainloop, take note of the [workaround](https://discourse.geek-kitchen.funkypenguin.co.nz/t/mail-server-funky-penguins-geek-cookbook/70/15) identified by [ggilley](https://discourse.geek-kitchen.funkypenguin.co.nz/u/ggilley)

--8<-- "recipe-footer.md"