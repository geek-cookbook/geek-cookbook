#Kanboard

Kanboard is a Kanban tool, developed by [Frédéric Guillot](https://github.com/fguillot). (_Who also happens to be the developer of my favorite RSS reader, [Miniflux](/recipes/miniflux/)_)

![Kanboard Screenshot](/images/kanboard.png)

Features include:

* Visualize your work
* Limit your work in progress to be more efficient
* Customize your boards according to your business activities
* Multiple projects with the ability to drag and drop tasks
* Reports and analytics
* Fast and simple to use
* Access from anywhere with a modern browser
* Plugins and integrations with external services
* Free, open source and self-hosted
* Super simple installation

## Ingredients

1. A [Kubernetes Cluster](/kubernetes/design/) including [Traefik Ingress](/kubernetes/traefik/)
2. A DNS name for your kanboard instance (*kanboard.example.com*, below) pointing to your [load balancer](/kubernetes/loadbalancer/), fronting your Traefik ingress

## Preparation

### Prepare traefik for namespace

When you deployed [Traefik via the helm chart](/kubernetes/traefik/), you would have customized ```values.yml``` for your deployment. In ```values.yml``` is a list of namespaces which Traefik is permitted to access. Update ```values.yml``` to include the *kanboard* namespace, as illustrated below:

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
mkdir /var/data/config/kanboard
```

### Create namespace

We use Kubernetes namespaces for service discovery and isolation between our stacks, so create a namespace for the kanboard stack with the following .yml:

```
cat <<EOF > /var/data/config/kanboard/namespace.yml
apiVersion: v1
kind: Namespace
metadata:
  name: kanboard
EOF
kubectl create -f /var/data/config/kanboard/namespace.yaml
```

### Create persistent volume claim

Persistent volume claims are a streamlined way to create a persistent volume and assign it to a container in a pod. Create a claim for the kanboard app and plugin data:

```
cat <<EOF > /var/data/config/kanboard/persistent-volumeclaim.yml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: kanboard-volumeclaim
  namespace: kanboard
  annotations:
    backup.kubernetes.io/deltas: P1D P7D  
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
kubectl create -f /var/data/config/kanboard/kanboard-volumeclaim.yaml
```

!!! question "What's that annotation about?"
    The annotation is used by [k8s-snapshots](/kubernetes/snapshots/) to create daily incremental snapshots of your persistent volumes. In this case, our volume is snapshotted daily, and copies kept for 7 days.

### Create ConfigMap

Kanboard's configuration is all contained within ```config.php```, which needs to be presented to the container. We _could_ maintain ```config.php``` in the persistent volume we created above, but this would require manually accessing the pod every time we wanted to make a change. 

Instead, we'll create ```config.php``` as a [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), meaning it "lives" within the Kuberetes cluster and can be **presented** to our pod. When we want to make changes, we simply update the ConfigMap (*delete and recreate, to be accurate*), and relaunch the pod.

Grab a copy of [config.default.php](https://github.com/kanboard/kanboard/blob/master/config.default.php), save it to ```/var/data/config/kanboard/config.php```, and customize it per [the guide](https://docs.kanboard.org/en/latest/admin_guide/config_file.html).

At the very least, I'd suggest making the following changes:
```
define('PLUGIN_INSTALLER', true);    // Yes, I want to install plugins using the UI
define('ENABLE_URL_REWRITE', false); // Yes, I want pretty URLs
```

Now create the configmap from config.php, by running ```kubectl create configmap -n kanboard kanboard-config --from-file=config.php```

## Serving

Now that we have a [namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), a [persistent volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/), and a [configmap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), we can create a [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [service](https://kubernetes.io/docs/concepts/services-networking/service/), and [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) for the kanboard [pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/). 

### Create deployment

Create a deployment to tell Kubernetes about the desired state of the pod (*which it will then attempt to maintain*). Note below that we mount the persistent volume **twice**, to both ```/var/www/app/data``` and ```/var/www/app/plugins```, using the subPath value to differentiate them. This trick avoids us having to provision **two** persistent volumes just for data mounted in 2 separate locations.

--8<-- "premix-cta.md"

```
cat <<EOF > /var/data/kanboard/deployment.yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  namespace: kanboard
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
        - image: kanboard/kanboard
          name: app
          volumeMounts:
            - name: kanboard-config
              mountPath: /var/www/app/config.php
              subPath: config.php
            - name: kanboard-app
              mountPath: /var/www/app/data
              subPath: data
            - name: kanboard-app
              mountPath: /var/www/app/plugins
              subPath: plugins
      volumes:
        - name: kanboard-app
          persistentVolumeClaim:
            claimName: kanboard-app
        - name: kanboard-config
          configMap:
            name: kanboard-config
EOF
kubectl create -f /var/data/kanboard/deployment.yml
```

Check that your deployment is running, with ```kubectl get pods -n kanboard```. After a minute or so, you should see a "Running" pod, as illustrated below:

```
[funkypenguin:~] % kubectl get pods -n kanboard
NAME                   READY     STATUS    RESTARTS   AGE
app-79f97f7db6-hsmfg   1/1       Running   0          11d
[funkypenguin:~] %
```

### Create service

The service resource "advertises" the availability of TCP port 80 in your pod, to the rest of the cluster (*constrained within your namespace*). It seems a little like overkill coming from the Docker Swarm's automated "service discovery" model, but the Kubernetes design allows for load balancing, rolling upgrades, and health checks of individual pods, without impacting the rest of the cluster elements.

```
cat <<EOF > /var/data/kanboard/service.yml
kind: Service
apiVersion: v1
metadata:
  name: app
  namespace: kanboard
spec:
  selector:
    app: app
  ports:
  - protocol: TCP
    port: 80
  clusterIP: None
EOF
kubectl create -f /var/data/kanboard/service.yml
```

Check that your service is deployed, with ```kubectl get services -n kanboard```. You should see something like this:

```
[funkypenguin:~] % kubectl get service -n kanboard
NAME      TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
app       ClusterIP   None         <none>        80/TCP    38d
[funkypenguin:~] %
```

### Create ingress

The ingress resource tells Traefik what to forward inbound requests for *kanboard.example.com* to your service (defined above), which in turn passes the request to the "app" pod. Adjust the config below for your domain.

```
cat <<EOF > /var/data/kanboard/ingress.yml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: app
  namespace: kanboard
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: kanboard.example.com
    http:
      paths:
      - backend:
          serviceName: app
          servicePort: 80
EOF
kubectl create -f /var/data/kanboard/ingress.yml
```

Check that your service is deployed, with ```kubectl get ingress -n kanboard```. You should see something like this:

```
[funkypenguin:~] % kubectl get ingress -n kanboard
NAME      HOSTS                         ADDRESS   PORTS     AGE
app       kanboard.funkypenguin.co.nz             80        38d
[funkypenguin:~] %
```

### Access Kanboard

At this point, you should be able to access your instance on your chosen DNS name (*i.e. https://kanboard.example.com*)


### Updating config.php

Since ```config.php``` is a ConfigMap now, to update it, make your local changes, and then delete and recreate the ConfigMap, by running:

```
kubectl delete configmap -n kanboard kanboard-config
kubectl create configmap -n kanboard kanboard-config --from-file=config.php
```

Then, in the absense of any other changes to the deployement definition, force the pod to restart by issuing a "null patch", as follows:

```
kubectl patch -n kanboard deployment app -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
```

### Troubleshooting

To look at the Kanboard pod's logs, run ```kubectl logs -n kanboard <name of pod per above> -f```. For further troubleshooting hints, see [Troubleshooting](/reference/kubernetes/troubleshooting/).

[^1]: The simplest deployment of Kanboard uses the default SQLite database backend, stored on the persistent volume. You can convert this to a "real" database running MySQL or PostgreSQL, and running an an additional database pod and service. Contact me if you'd like further details ;)

--8<-- "recipe-footer.md"