# SSL Certificates

When you expose applications running within your cluster to the outside world, you're going to want to protect these with SSL certificates. Typically, this'll be SSL certificates used by browsers to access your Ingress resources over HTTPS, but SSL certificates would be used for other externally-facing services, for example OpenLDAP, docker-mailserver, etc.

!!! question "Why do I need SSL if it's just internal?"
    It's true that you could expose applications via HTTP only, and **not** bother with SSL. By doing so, however, you "train yourself"[^1] to ignore SSL certificates / browser security warnings.

    One day, this behaviour will bite you in the ass. 
    
    If you want to be a person who relies on privacy and security, then insist on privacy and security **everywhere**.

    Plus, once you put in the effort to setup automated SSL certificates _once_, it's literally **no** extra effort to use them everywhere!

I've split this section, conceptually, into 3 separate tasks:

1. Setup [Cert Manager](/kubernetes/ssl-certificates/cert-manager/), a controller whose job it is to request / renew certificates
2. Setup "[Issuers](/kubernetes/ssl-certificates/letsencrypt-issuers/)" for LetsEncrypt, which Cert Manager will use to request certificates
3. Setup a [wildcard certificate](/kubernetes/ssl-certificates/letsencrypt-wildcard/) in such a way that it can be used by Ingresses like Traefik or Ngnix

--8<-- "recipe-footer.md"

[^1]: I had a really annoying but smart boss once who taught me this. Hi Mark! :wave:
