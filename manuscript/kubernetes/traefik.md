# Traefik

This recipe utilises the [traefik helm chart](https://github.com/helm/charts/tree/master/stable/traefik) to proving LetsEncrypt-secured HTTPS access to multiple containers within your cluster.

## Ingredients

1. [Kubernetes cluster](/kubernetes/cluster/)
2. [Helm](/kubernetes/helm/) installed and initialised in your cluster

## Preparation

### Clone helm charts

Clone the helm charts, by running:

```
git clone https://github.com/helm/charts
```

Change to stable/traefik:

```
cd charts/stable/traefik
```

### Edit values.yaml

The beauty of the helm approach is that all the complexity of the Kubernetes elements' YAML files are hidden from you (created using templates), and all your changes go into values.yaml.

These are my values, you'll need to adjust for your own situation:

```
imageTag: alpine
serviceType: NodePort
# yes, we're not listening on 80 or 443 because we don't want to pay for a loadbalancer IP to do this. I use poor-mans-k8s-lb instead
service:
  nodePorts:
    http: 30080
    https: 30443
cpuRequest: 1m
memoryRequest: 100Mi
cpuLimit: 1000m
memoryLimit: 500Mi

ssl:
  enabled: true
  enforced: true
debug:
  enabled: false

rbac:
  enabled: true
dashboard:
  enabled: true
  domain: traefik.funkypenguin.co.nz
kubernetes:
  # set these to all the namespaces you intend to use. I standardize on one-per-stack. You can always add more later
  namespaces:
    - kube-system
    - unifi
    - kanboard
    - nextcloud
    - huginn
    - miniflux
accessLogs:
  enabled: true
acme:
  persistence:
     enabled: true
     # Add the necessary annotation to backup ACME store with k8s-snapshots
     annotations: { "backup.kubernetes.io/deltas: P1D P7D" }
  staging: false
  enabled: true
  logging: true
  email: "<my letsencrypt email>"
  challengeType: "dns-01"
  dnsProvider:
    name: cloudflare
    cloudflare:
      CLOUDFLARE_EMAIL: "<my cloudlare email"
      CLOUDFLARE_API_KEY: "<my cloudflare API key>"
  domains:
    enabled: true
    domainsList:
      - main: "*.funkypenguin.co.nz" # name of the wildcard domain name for the certificate
      - sans:
          - "funkypenguin.co.nz"
metrics:
  prometheus:
    enabled: true
```

!!! note
    The helm chart doesn't enable the Traefik dashboard by default. I intend to add an oauth_proxy pod to secure this, in a future recipe update.

### Prepare phone-home pod

[Remember](/kubernetes/loadbalancer/) how our load balancer design ties a phone-home container to another container using a pod, so that the phone-home container can tell our external load balancer (_using a webhook_) where to send our traffic?

Since we deployed Traefik using helm, we need to take a slightly different approach, so we'll create a pod with an affinity which ensures it runs on the same host which runs the Traefik container (_more precisely, containers with the label app=traefik_).

Create phone-home.yaml as follows:

```
apiVersion: v1
kind: Pod
metadata:
  name: phonehome-traefik
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - traefik
        topologyKey: failure-domain.beta.kubernetes.io/zone
  containers:
        - image: funkypenguin/poor-mans-k8s-lb
          imagePullPolicy: Always
          name: phonehome-traefik
          env:
          - name: REPEAT_INTERVAL
            value: "600"
          - name: FRONTEND_PORT
            value: "443"
          - name: BACKEND_PORT
            value: "30443"
          - name: NAME
            value: "traefik"
          - name: WEBHOOK
            value: "https://<your loadbalancer hostname>:9000/hooks/update-haproxy"
          - name: WEBHOOK_TOKEN
            valueFrom:
              secretKeyRef:
                name: traefik-credentials
                key: webhook_token.secret
```

Create your webhook token secret by running:

```
echo -n "imtoosecretformyshorts" > webhook_token.secret
kubectl create secret generic traefik-credentials --from-file=webhook_token.secret
```

!!! warning
    Yes, the "-n" in the echo statement is needed. [Read here for why](https://www.funkypenguin.co.nz/beware-the-hidden-newlines-in-kubernetes-secrets/).

## Serving

### Install the chart

To install the chart, simply run ```helm install stable/traefik --name traefik --namespace kube-system```

That's it, traefik is running.

You can confirm this by running ```kubectl get pods```, and even watch the traefik logs, by running ```kubectl logs -f traefik<tab-to-autocomplete>```

### Deploy the phone-home pod

We still can't access traefik yet, since it's listening on port 30443 on node it happens to be running on. We'll launch our phone-home pod, to tell our [load balancer](/kubernetes/loadbalancer/) where to send incoming traffic on port 443.

Optionally, on your loadbalancer VM, run ```journalctl -u webhook -f``` to watch for the container calling the webhook.

Run ```kubectl create -f phone-home.yaml``` to create the pod.

Run ```kubectl get pods -o wide``` to confirm that both the phone-home pod and the traefik pod are on the same node:

```
# kubectl get pods -o wide
NAME                       READY     STATUS              RESTARTS   AGE       IP           NODE
phonehome-traefik          1/1       Running             0          20h       10.56.2.55   gke-penguins-are-sexy-8b85ef4d-2c9g
traefik-69db67f64c-5666c   1/1       Running             0          10d       10.56.2.30   gkepenguins-are-sexy-8b85ef4d-2c9g
```

Now browse to https://<your load balancer>, and you should get a valid SSL cert, along with a 404 error (_you haven't deployed any other recipes yet_)

### Making changes

If you change a value in values.yaml, and want to update the traefik pod, run:

```
helm upgrade --values values.yml traefik stable/traefik --recreate-pods
```

## Review

We're doneburgers! 🍔 We now have all the pieces to safely deploy recipes into our Kubernetes cluster, knowing:

1. Our HTTPS traffic will be secured with LetsEncrypt (thanks Traefik!)
2. Our non-HTTPS ports (like UniFi adoption) will be load-balanced using an free-to-scale [external load balancer](/kubernetes/loadbalancer/)
3. Our persistent data will be [automatically backed up](/kubernetes/snapshots/)

Here's a recap:

* [Start](/kubernetes/) - Why Kubernetes?
* [Design](/kubernetes/design/) - How does it fit together?
* [Cluster](/kubernetes/cluster/) - Setup a basic cluster
* [Load Balancer](/kubernetes/loadbalancer/) Setup inbound access
* [Snapshots](/kubernetes/snapshots/) - Automatically backup your persistent data
* [Helm](/kubernetes/helm/) - Uber-recipes from fellow geeks
* Traefik (this page) - Traefik Ingress via Helm

## Where to next?

I'll be adding more Kubernetes versions of existing recipes soon. Check out the [MQTT](/recipes/mqtt/) recipe for a start!

[^1]: It's kinda lame to be able to bring up Traefik but not to use it. I'll be adding the oauth_proxy element shortly, which will make this last step a little more conclusive and exciting!

--8<-- "recipe-footer.md"