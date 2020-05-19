# Load Balancer

One of the issues I encountered early on in migrating my Docker Swarm workloads to Kubernetes on GKE, was how to reliably permit inbound traffic into the cluster.

There were several complications with the "traditional" mechanisms of providing a load-balanced ingress, not the least of which was cost. I also found that even if I paid my cloud provider (_Google_) for a load-balancer Kubernetes service, this service required a unique IP per exposed port, which was incompatible with my mining pool empire (_mining pools need to expose multiple ports on the same DNS name_).

See further examination of the problem and possible solutions in the [Kubernetes design](kubernetes/design/#the-challenges-of-external-access) page.

This recipe details a simple design to permit the exposure of as many ports as you like, on a single public IP, to a cluster of Kubernetes nodes running as many pods/containers as you need, with services exposed via NodePort.

![Kubernetes Design](/images/kubernetes-cluster-design.png)

## Ingredients

1. [Kubernetes cluster](/kubernetes/cluster/)
2. VM _outside_ of Kubernetes cluster, with a fixed IP address. Perhaps, on a [$5/month Digital Ocean Droplet](https://www.digitalocean.com/?refcode=e33b78ad621b).. (_yes, another referral link. Mooar 🍷 for me!_)
3. Geek-Fu required : 🐧🐧🐧 (_complex - inline adjustments required_)


## Preparation

### Summary

### Create LetsEncrypt certificate

!!! warning
    Safety first, folks. You wouldn't run a webhook exposed to the big bad ol' internet without first securing it with a valid SSL certificate? Of course not, I didn't think so!

Use whatever method you prefer to generate (and later, renew) your LetsEncrypt cert. The example below uses the CertBot docker image for CloudFlare DNS validation, since that's what I've used elsewhere.

We **could** run our webhook as a simple HTTP listener, but really, in a world where LetsEncrypt cacn assign you a wildcard certificate in under 30 seconds, thaht's unforgivable. Use the following **general** example to create a LetsEncrypt wildcard cert for your host:

In my case, since I use CloudFlare, I create /etc/webhook/letsencrypt/cloudflare.ini:

```
dns_cloudflare_email=davidy@funkypenguin.co.nz
dns_cloudflare_api_key=supersekritnevergonnatellyou
```

I request my cert by running:
```
cd /etc/webhook/
docker run -ti --rm -v "$(pwd)"/letsencrypt:/etc/letsencrypt certbot/dns-cloudflare --preferred-challenges dns certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini -d ''*.funkypenguin.co.nz'
```

!!! question
    Why use a wildcard cert? So my enemies can't examine my certs to enumerate my various services and discover my weaknesses, of course!

I add the following as a cron command to renew my certs every day:

```
cd /etc/webhook && docker run -ti --rm -v "$(pwd)"/letsencrypt:/etc/letsencrypt certbot/dns-cloudflare renew --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini
```

Once you've confirmed you've got a valid LetsEncrypt certificate stored in ```/etc/webhook/letsencrypt/live/<your domain>/fullcert.pem```, proceed to the next step..

### Install webhook

We're going to use https://github.com/adnanh/webhook to run our webhook. On some distributions (_❤️ ya, Debian!_), webhook and its associated systemd config can be installed by running ```apt-get install webhook```.

### Create webhook config

We'll create a single webhook, by creating ```/etc/webhook/hooks.json``` as follows. Choose a nice secure random string for your MY_TOKEN value!

```
mkdir /etc/webhook
export MY_TOKEN=ilovecheese
echo << EOF > /etc/webhook/hooks.json
[
  {
    "id": "update-haproxy",
    "execute-command": "/etc/webhook/update-haproxy.sh",
    "command-working-directory": "/etc/webhook",
    "pass-arguments-to-command":
    [
      {
        "source": "payload",
        "name": "name"
      },
      {
        "source": "payload",
        "name": "frontend-port"
      },
      {
        "source": "payload",
        "name": "backend-port"
      },
      {
        "source": "payload",
        "name": "dst-ip"
      },
      {
        "source": "payload",
        "name": "action"
      }
    ],
   "trigger-rule":
    {
      "match":
      {
        "type": "value",
        "value": "$MY_TOKEN",
	"parameter":
	{
        "source": "header",
        "name": "X-Funkypenguin-Token"
      }
      }
    }
  }
]
EOF
```

!!! note
    Note that to avoid any bozo from calling our we're matching on a token header in the request called ```X-Funkypenguin-Token```. Webhook will **ignore** any request which doesn't include a matching token in the request header.

### Update systemd for webhook

!!! note
    This section is particular to Debian Stretch and its webhook package. If you're using another OS for your VM, just ensure that you can start webhook with a config similar to the one illustrated below.

Since we want to force webhook to run in secure mode (_no point having a token if it can be extracted from a simple packet capture!_) I ran ```systemctl edit webhook```, and pasted in the following:

```
[Service]
# Override the default (non-secure) behaviour of webhook by passing our certificate details and custom hooks.json location
ExecStart=
ExecStart=/usr/bin/webhook -hooks /etc/webhook/hooks.json -verbose -secure -cert /etc/webhook/letsencrypt/live/funkypenguin.co.nz/fullchain.pem -key /etc/webhook/letsencrypt/live/funkypenguin.co.nz/privkey.pem
```

Then I restarted webhook by running ```systemctl enable webhook && systemctl restart webhook```. I watched the subsequent logs by running ```journalctl -u webhook -f```

### Create /etc/webhook/update-haproxy.sh

When successfully authenticated with our top-secret token, our webhook will execute a local script, defined as follows (_yes, you should create this file_):

```
#!/bin/bash

NAME=$1
FRONTEND_PORT=$2
BACKEND_PORT=$3
DST_IP=$4
ACTION=$5

# Bail if we haven't received our expected parameters
if [[ "$#" -ne 5 ]]
then
  echo "illegal number of parameters"
  exit 2;
fi

# Either add or remove a service based on $ACTION
case $ACTION in
	add)
		# Create the portion of haproxy config
		cat << EOF > /etc/webhook/haproxy/$FRONTEND_PORT.inc
### >> Used to run $NAME:${FRONTEND_PORT}
frontend ${FRONTEND_PORT}_frontend
  bind *:$FRONTEND_PORT
  mode tcp
  default_backend ${FRONTEND_PORT}_backend

backend ${FRONTEND_PORT}_backend
  mode tcp
  balance roundrobin
  stick-table type ip size 200k expire 30m
  stick on src
  server s1 $DST_IP:$BACKEND_PORT
### << Used to run $NAME:$FRONTEND_PORT
EOF
		;;
	delete)
		rm /etc/webhook/haproxy/$FRONTEND_PORT.inc
		;;
	*)
		echo "Invalid action $ACTION"
		exit 2
esac

# Concatenate all the haproxy configs into a single file
cat /etc/webhook/haproxy/global /etc/webhook/haproxy/*.inc > /etc/webhook/haproxy/pre_validate.cfg

# Validate the generated config
haproxy -f /etc/webhook/haproxy/pre_validate.cfg -c

# If validation was successful, only _then_ copy it over to /etc/haproxy/haproxy.cfg, and reload
if [[ $? -gt 0 ]]
then
	echo "HAProxy validation failed, not continuing"
	exit 2
else
  # Remember what the original file looked like
  m1=$(md5sum "/etc/haproxy/haproxy.cfg")

  # Overwrite the original file
  cp /etc/webhook/haproxy/pre_validate.cfg /etc/haproxy/haproxy.cfg

  # Get MD5 of new file
  m2=$(md5sum "/etc/haproxy/haproxy.cfg")

  # Only if file has changed, then we need to reload haproxy
  if [ "$m1" != "$m2" ] ; then
    echo "HAProxy config has changed, reloading"
    systemctl reload haproxy
  fi
fi
```

### Create /etc/webhook/haproxy/global

Create ```/etc/webhook/haproxy/global``` and populate with something like the following. This will be the non-dynamically generated part of our HAProxy config:

```
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # Default ciphers to use on SSL-enabled listening sockets.
        # For more information, see ciphers(1SSL). This list is from:
        #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
        # An alternative list with additional directives can be obtained from
        #  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
        ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
        ssl-default-bind-options no-sslv3

defaults
        log     global
        mode    tcp
        option  tcplog
        option  dontlognull
        timeout connect 5000
        timeout client  5000000
        timeout server  5000000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
```

## Serving

### Take the bait!

Whew! We now have all the components of our automated load-balancing solution in place. Browse to your VM's FQDN at https://whatever.it.is:9000/hooks/update-haproxy, and you should see the text "_Hook rules were not satisfied_", with a valid SSL certificate (_You didn't send a token_).

If you don't see the above, then check the following:

1. Does the webhook verbose log (```journalctl -u webhook -f```) complain about invalid arguments or missing files?
2. Is port 9000 open to the internet on your VM?

### Apply to pods

You'll see me use this design in any Kubernetes-based recipe which requires container-specific ports, like UniFi. Here's an excerpt of the .yml which defines the UniFi controller:

```
<snip>
spec:
  containers:
    - image: linuxserver/unifi
      name: controller
      volumeMounts:
        - name: controller-volumeclaim
          mountPath: /config
    - image: funkypenguin/poor-mans-k8s-lb
      imagePullPolicy: Always
      name: 8080-phone-home
      env:
      - name: REPEAT_INTERVAL
        value: "600"
      - name: FRONTEND_PORT
        value: "8080"
      - name: BACKEND_PORT
        value: "30808"
      - name: NAME
        value: "unifi-adoption"
      - name: WEBHOOK
        value: "https://my-secret.url.wouldnt.ya.like.to.know:9000/hooks/update-haproxy"
      - name: WEBHOOK_TOKEN
        valueFrom:
          secretKeyRef:
            name: unifi-credentials
            key: webhook_token.secret
<snip>
```

The takeaways here are:

1. We add the funkypenguin/poor-mans-k8s-lb containier to any pod which has special port requirements, forcing the container to run on the same node as the other containers in the pod (_in this case, the UniFi controller_)
2. We use a Kubernetes secret for the webhook token, so that our .yml can be shared without exposing sensitive data

Here's what the webhook logs look like when the above is added to the UniFi deployment:

```
Feb 06 23:04:28 haproxy2 webhook[1433]: [webhook] 2019/02/06 23:04:28 Started POST /hooks/update-haproxy
Feb 06 23:04:28 haproxy2 webhook[1433]: [webhook] 2019/02/06 23:04:28 update-haproxy got matched
Feb 06 23:04:28 haproxy2 webhook[1433]: [webhook] 2019/02/06 23:04:28 update-haproxy hook triggered successfully
Feb 06 23:04:28 haproxy2 webhook[1433]: [webhook] 2019/02/06 23:04:28 Completed 200 OK in 2.123921ms
Feb 06 23:04:28 haproxy2 webhook[1433]: [webhook] 2019/02/06 23:04:28 executing /etc/webhook/update-haproxy.sh (/etc/webhook/update-haproxy.sh) with arguments ["/etc/webhook/update-haproxy.sh" "unifi-adoption" "8080" "30808" "35.244.91.178" "add"] and environment [] using /etc/webhook as cwd
Feb 06 23:04:28 haproxy2 webhook[1433]: [webhook] 2019/02/06 23:04:28 command output: Configuration file is valid
<HAProxy restarts>
```


## Move on..

Still with me? Good. Move on to setting up an ingress SSL terminating proxy with Traefik..

* [Start](/kubernetes/start/) - Why Kubernetes?
* [Design](/kubernetes/design/) - How does it fit together?
* [Cluster](/kubernetes/cluster/) - Setup a basic cluster
* Load Balancer (this page) - Setup inbound access
* [Snapshots](/kubernetes/snapshots/) - Automatically backup your persistent data
* [Helm](/kubernetes/helm/) - Uber-recipes from fellow geeks
* [Traefik](/kubernetes/traefik/) - Traefik Ingress via Helm


## Chef's Notes

1. This is MVP of the load balancer solution. Any suggestions for improvements are welcome 😉