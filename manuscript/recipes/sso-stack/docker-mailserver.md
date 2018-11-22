docker run -ti --rm  \
-v "$(pwd)"/letsencrypt:/etc/letsencrypt \
-v "$(pwd)"/cloudflare.ini:/cloudflare.ini \
certbot/dns-cloudflare \
certonly \
--dns-cloudflare \
--dns-cloudflare-credentials=/cloudflare.ini \
-d mail.observe.global



```
root@cloud:/var/data/docker-mailserver# docker run -ti --rm  -v "$(pwd)"/letsencrypt:/etc/letsencrypt -v "$(pwd)"/cloudflare.ini:/cloudflare.ini certbot/dns-cloudflare certonly --dns-cloudflare --dns-cloudflare-credentials=/cloudflare.ini -d mail.observe.global
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator dns-cloudflare, Installer None
Enter email address (used for urgent renewal and security notices) (Enter 'c' to
cancel): cam@0sum.club

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please read the Terms of Service at
https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf. You must
agree in order to register with the ACME server at
https://acme-v02.api.letsencrypt.org/directory
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(A)gree/(C)ancel: A

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing to share your email address with the Electronic Frontier
Foundation, a founding partner of the Let's Encrypt project and the non-profit
organization that develops Certbot? We'd like to send you email about our work
encrypting the web, EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: N
Obtaining a new certificate
Performing the following challenges:
dns-01 challenge for mail.observe.global
Unsafe permissions on credentials configuration file: /cloudflare.ini
Waiting 10 seconds for DNS changes to propagate
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/mail.observe.global/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/mail.observe.global/privkey.pem
   Your cert will expire on 2019-01-30. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - Your account credentials have been saved in your Certbot
   configuration directory at /etc/letsencrypt. You should make a
   secure backup of this folder now. This configuration directory will
   also contain certificates and private keys obtained by Certbot so
   making regular backups of this folder is ideal.
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le

root@cloud:/var/data/docker-mailserver#
```
