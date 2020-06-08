#Miniflux

Miniflux is a lightweight RSS reader, developed by [Frédéric Guillot](https://github.com/fguillot). (_Who also happens to be the developer of the favorite Open Source Kanban app, [Kanboard](/recipes/kanboard/)_)

![Miniflux Screenshot](/images/miniflux.png)

!!! tip "Sponsored Project"
    Miniflux is one of my [sponsored projects](/sponsored-projects/) - a project I financially support on a regular basis because of its utility to me. Although I get to process my RSS feeds less frequently than I'd like to!

I've [reviewed Miniflux in detail on my blog](https://www.funkypenguin.co.nz/review/miniflux-lightweight-self-hosted-rss-reader/), but features (among many) that I appreciate:

* Compatible with the Fever API, read your feeds through existing mobile and desktop clients (_This is the killer feature for me. I hardly ever read RSS on my desktop, I typically read on my iPhone or iPad, using [Fiery Feeds](http://cocoacake.net/apps/fiery/) or my new squeeze, [Unread](https://www.goldenhillsoftware.com/unread/)_)
* Send your bookmarks to Pinboard, Wallabag, Shaarli or Instapaper (_I use this to automatically pin my bookmarks for collection on my [blog](https://www.funkypenguin.co.nz/blog/)_)
* Feeds can be configured to download a "full" version of the content (_rather than an excerpt_)
* Use the Bookmarklet to subscribe to a website directly from any browsers

!!! abstract "2.0+ is a bit different"
    [Some things changed](https://docs.miniflux.net/en/latest/migration.html) when Miniflux 2.0 was released. For one thing, the only supported database is now postgresql (_no more SQLite_). External themes are gone, as is PHP (_in favor of golang_). It's been a controversial change, but I'm keen on minimal and single-purpose, so I'm still very happy with the direction of development. The developer has laid out his [opinions](https://docs.miniflux.net/en/latest/opinionated.html) re the decisions he's made in the course of development.


## Ingredients

1. A [Kubernetes Cluster](/kubernetes/design/) including [Traefik Ingress](/kubernetes/traefik/)
2. A DNS name for your miniflux instance (*miniflux.example.com*, below) pointing to your [load balancer](/kubernetes/loadbalancer/), fronting your Traefik ingress

## Preparation

### Prepare traefik for namespace

When you deployed [Traefik via the helm chart](/kubernetes/traefik/), you would have customized ```values.yml``` for your deployment. In ```values.yml``` is a list of namespaces which Traefik is permitted to access. Update ```values.yml``` to include the *miniflux* namespace, as illustrated below:

```
<snip>
kubernetes:
  namespaces:
    - kube-system
    - nextcloud
    - kanboard
    - miniflux
<snip>
```

If you've updated ```values.yml```, upgrade your traefik deployment via helm, by running ```helm upgrade --values values.yml traefik stable/traefik --recreate-pods```

### Create data locations

Although we could simply bind-mount local volumes to a local Kubuernetes cluster, since we're targetting a cloud-based Kubernetes deployment, we only need a local path to store the YAML files which define the various aspects of our Kubernetes deployment.

```
mkdir /var/data/config/miniflux
```

### Create namespace

We use Kubernetes namespaces for service discovery and isolation between our stacks, so create a namespace for the miniflux stack with the following .yml:

```
cat <<EOF > /var/data/config/miniflux/namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: miniflux
EOF
kubectl create -f /var/data/config/miniflux/namespace.yaml
```

### Create persistent volume claim

Persistent volume claims are a streamlined way to create a persistent volume and assign it to a container in a pod. Create a claim for the miniflux postgres database:

```
cat <<EOF > /var/data/config/miniflux/db-persistent-volumeclaim.yml
kkind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: miniflux-db
  namespace: miniflux
  annotations:
    backup.kubernetes.io/deltas: P1D P7D
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
kubectl create -f /var/data/config/miniflux/db-persistent-volumeclaim.yaml
```

!!! question "What's that annotation about?"
    The annotation is used by [k8s-snapshots](/kubernetes/snapshots/) to create daily incremental snapshots of your persistent volumes. In this case, our volume is snapshotted daily, and copies kept for 7 days.

### Create secrets

It's not always desirable to have sensitive data stored in your .yml files. Maybe you want to check your config into a git repository, or share it. Using Kubernetes Secrets means that you can create "secrets", and use these in your deployments by name, without exposing their contents. Run the following, replacing ```imtoosexyformyadminpassword```, and the ```mydbpass``` value in both postgress-password.secret **and** database-url.secret:

```
echo -n "imtoosexyformyadminpassword" > admin-password.secret
echo -n "mydbpass"                    > postgres-password.secret
echo -n "postgres://miniflux:mydbpass@db/miniflux?sslmode=disable" > database-url.secret

kubectl create secret -n mqtt generic miniflux-credentials \
   --from-file=admin-password.secret \
   --from-file=database-url.secret \
   --from-file=database-url.secret
```

!!! tip "Why use ```echo -n```?"
    Because. See [my blog post here](https://www.funkypenguin.co.nz/beware-the-hidden-newlines-in-kubernetes-secrets/) for the pain of hunting invisible newlines, that's why!


## Serving

Now that we have a [namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), a [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/), and a [configmap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), we can create [deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [services](https://kubernetes.io/docs/concepts/services-networking/service/), and an [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) for the miniflux [pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/). 

### Create db deployment

Deployments tell Kubernetes about the desired state of the pod (*which it will then attempt to maintain*). Create the db deployment by excecuting the following. Note that the deployment refers to the secrets created above.

!!! tip
        I share (_with my [sponsors](https://github.com/sponsors/funkypenguin)_) a private "_premix_" git repository, which includes necessary .yml files for all published recipes. This means that sponsors can launch any recipe with just a ```git pull``` and a ```kubectl create -f *.yml``` 👍

```
cat <<EOF > /var/data/miniflux/db-deployment.yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: miniflux
  name: db
  labels:
    app: db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
        - image: postgres:11
          name: db
          volumeMounts:
            - name: miniflux-db
              mountPath: /var/lib/postgresql/data
          env:
          - name: POSTGRES_USER
            value: "miniflux"
          - name: POSTGRES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: miniflux-credentials
                key: postgres-password.secret
      volumes:
        - name: miniflux-db
          persistentVolumeClaim:
            claimName: miniflux-db
```

### Create app deployment

Create the app deployment by excecuting the following. Again, note that the deployment refers to the secrets created above.

```
cat <<EOF > /var/data/miniflux/app-deployment.yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: miniflux
  name: app
  labels:
    app: app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
        - image: miniflux/miniflux
          name: app
          env:
          # This is necessary for the miniflux to update the db schema, even on an empty DB
          - name: CREATE_ADMIN
            value: "1"
          - name: RUN_MIGRATIONS
            value: "1"
          - name: ADMIN_USERNAME
            value: "admin"
          - name: ADMIN_PASSWORD
            valueFrom:
              secretKeyRef:
                name: miniflux-credentials
                key: admin-password.secret
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: miniflux-credentials
                key: database-url.secret
EOF
kubectl create -f /var/data/miniflux/deployment.yml
```

### Check pods

Check that your deployment is running, with ```kubectl get pods -n miniflux```. After a minute or so, you should see 2 "Running" pods, as illustrated below:

```
[funkypenguin:~] % kubectl get pods -n miniflux
NAME                   READY     STATUS    RESTARTS   AGE
app-667c667b75-5jjm9   1/1       Running   0          4d
db-fcd47b88f-9vvqt     1/1       Running   0          4d
[funkypenguin:~] %
```

### Create db service

The db service resource "advertises" the availability of PostgreSQL's port (TCP 5432) in your pod, to the rest of the cluster (*constrained within your namespace*). It seems a little like overkill coming from the Docker Swarm's automated "service discovery" model, but the Kubernetes design allows for load balancing, rolling upgrades, and health checks of individual pods, without impacting the rest of the cluster elements.

```
cat <<EOF > /var/data/miniflux/db-service.yml
kind: Service
apiVersion: v1
metadata:
  name: db
  namespace: miniflux
spec:
  selector:
    app: db
  ports:
  - protocol: TCP
    port: 5432
  clusterIP: None
EOF
kubectl create -f /var/data/miniflux/service.yml
```

### Create app service

The app service resource "advertises" the availability of miniflux's HTTP listener port (TCP 8080) in your pod. This is the service which will be referred to by the ingress (below), so that Traefik can route incoming traffic to the miniflux app.


```
cat <<EOF > /var/data/miniflux/app-service.yml
kind: Service
apiVersion: v1
metadata:
  name: app
  namespace: miniflux
spec:
  selector:
    app: app
  ports:
  - protocol: TCP
    port: 8080
  clusterIP: None
EOF
kubectl create -f /var/data/miniflux/app-service.yml
```

### Check services

Check that your services are deployed, with ```kubectl get services -n miniflux```. You should see something like this:

```
[funkypenguin:~] % kubectl get services -n miniflux
NAME      TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
app       ClusterIP   None         <none>        8080/TCP   55d
db        ClusterIP   None         <none>        5432/TCP   55d
[funkypenguin:~] %
```

### Create ingress

The ingress resource tells Traefik what to forward inbound requests for *miniflux.example.com* to your service (defined above), which in turn passes the request to the "app" pod. Adjust the config below for your domain.

```
cat <<EOF > /var/data/miniflux/ingress.yml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: app
  namespace: miniflux
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: miniflux.example.com
    http:
      paths:
      - backend:
          serviceName: app
          servicePort: 8080
EOF
kubectl create -f /var/data/miniflux/ingress.yml
```

Check that your service is deployed, with ```kubectl get ingress -n miniflux```. You should see something like this:

```
[funkypenguin:~] 130 % kubectl get ingress -n miniflux
NAME      HOSTS                         ADDRESS   PORTS     AGE
app       miniflux.funkypenguin.co.nz             80        55d
[funkypenguin:~] %
```

### Access Miniflux

At this point, you should be able to access your instance on your chosen DNS name (*i.e. https://miniflux.example.com*)


### Troubleshooting

To look at the Miniflux pod's logs, run ```kubectl logs -n miniflux <name of pod per above> -f```. For further troubleshooting hints, see [Troubleshooting](/reference/kubernetes/troubleshooting/).