# Snapshots

Before we get carried away creating pods, services, deployments etc, let's spare a thought for _security_... (_DevSecPenguinOps, here we come!_). In the context of this recipe, security refers to safe-guarding your data from accidental loss, as well as malicious impact.

Under [Docker Swarm](https://geek-cookbook.funkypenguin.co.nz/)ha-docker-swarm/design/), we used [shared storage](https://geek-cookbook.funkypenguin.co.nz/)ha-docker-swarm/shared-storage-ceph/) with [Duplicity](https://geek-cookbook.funkypenguin.co.nz/)recipes/duplicity/) (or [ElkarBackup](recipes/elkarbackup/)) to automate backups of our persistent data.

Now that we're playing in the deep end with Kubernetes, we'll need a Cloud-native backup solution...

It bears repeating though - don't be like [Cameron](http://haltandcatchfire.wikia.com/wiki/Cameron_Howe). Backup your stuff.

<iframe width="560" height="315" src="https://www.youtube.com/embed/1UtFeMoqVHQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

This recipe employs a clever tool ([miracle2k/k8s-snapshots](https://github.com/miracle2k/k8s-snapshots)), running _inside_ your cluster, to trigger automated snapshots of your persistent volumes, using your cloud provider's APIs.

## Ingredients

1. [Kubernetes cluster](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/cluster/) with either AWS or GKE (currently, but apparently other providers are [easy to implement](https://github.com/miracle2k/k8s-snapshots/blob/master/k8s_snapshots/backends/abstract.py))
2. Geek-Fu required :  (_medium - minor adjustments may be required_)

## Preparation

### Create RoleBinding (GKE only)

If you're running GKE, run the following to create a RoleBinding, allowing your user to grant rights-it-doesn't-currently-have to the service account responsible for creating the snapshots:

```kubectl create clusterrolebinding your-user-cluster-admin-binding \
 --clusterrole=cluster-admin --user=<your user@yourdomain>```

!!! question
    Why do we have to do this? Check [this blog post](https://www.funkypenguin.co.nz/workaround-blocked-attempt-to-grant-extra-privileges-on-gke/) for details

### Apply RBAC

If your cluster is RBAC-enabled (_it probably is_), you'll need to create a ClusterRole and ClusterRoleBinding to allow k8s_snapshots to see your PVs and friends:

```
kubectl apply -f https://raw.githubusercontent.com/miracle2k/k8s-snapshots/master/rbac.yaml
```

## Serving

### Deploy the pod

Ready? Run the following to create a deployment in to the kube-system namespace:

```
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-snapshots
  namespace: kube-system
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: k8s-snapshots
    spec:
      containers:
      - name: k8s-snapshots
        image: elsdoerfer/k8s-snapshots:v2.0
EOF
```

Confirm your pod is running and happy by running ```kubectl get pods -n kubec-system```, and ```kubectl -n kube-system logs k8s-snapshots<tab-to-auto-complete>```

### Pick PVs to snapshot

k8s-snapshots relies on annotations to tell it how frequently to snapshot your PVs. A PV requires the ```backup.kubernetes.io/deltas``` annotation in order to be snapshotted.

From the k8s-snapshots README:

```
The generations are defined by a list of deltas formatted as ISO 8601 durations (this differs from tarsnapper). PT60S or PT1M means a minute, PT12H or P0.5D is half a day, P1W or P7D is a week. The number of backups in each generation is implied by it's and the parent generation's delta.

For example, given the deltas PT1H P1D P7D, the first generation will consist of 24 backups each one hour older than the previous (or the closest approximation possible given the available backups), the second generation of 7 backups each one day older than the previous, and backups older than 7 days will be discarded for good.

The most recent backup is always kept.

The first delta is the backup interval.
```

To add the annotation to an existing PV, run something like this:

```
kubectl patch pv pvc-01f74065-8fe9-11e6-abdd-42010af00148 -p \
  '{"metadata": {"annotations": {"backup.kubernetes.io/deltas": "P1D P30D P360D"}}}'
```

To add the annotation to a _new_ PV, add the following annotation to your **PVC**:

```
backup.kubernetes.io/deltas: PT1H P2D P30D P180D
```

Here's an example of the PVC for the UniFi recipe, which includes 7 daily snapshots of the PV:

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: controller-volumeclaim
  namespace: unifi
  annotations:
    backup.kubernetes.io/deltas: P1D P7D
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

And here's what my snapshot list looks like after a few days:

![Kubernetes Snapshots](https://geek-cookbook.funkypenguin.co.nz/)images/kubernetes-snapshots.png)

### Snapshot a non-Kubernetes volume (optional)

If you're running traditional compute instances with your cloud provider (I do this for my poor man's load balancer), you might want to backup _these_ volumes as well.

To do so, first create a custom resource, ```SnapshotRule```:

```
cat <<EOF | kubectl create -f -
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: snapshotrules.k8s-snapshots.elsdoerfer.com
spec:
  group: k8s-snapshots.elsdoerfer.com
  version: v1
  scope: Namespaced
  names:
    plural: snapshotrules
    singular: snapshotrule
    kind: SnapshotRule
    shortNames:
    - sr
EOF
```

Then identify the volume ID of your volume, and create an appropriate ```SnapshotRule```:

```
cat <<EOF | kubectl apply -f -
apiVersion: "k8s-snapshots.elsdoerfer.com/v1"
kind: SnapshotRule
metadata:
  name: haproxy-badass-loadbalancer
spec:
  deltas: P1D P7D
  backend: google
  disk:
     name: haproxy2
     zone: australia-southeast1-a
EOF
```

!!! note
    Example syntaxes for the SnapshotRule for different providers can be found at https://github.com/miracle2k/k8s-snapshots/tree/master/examples

## Move on..

Still with me? Good. Move on to understanding Helm charts...

* [Start](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/start/) - Why Kubernetes?
* [Design](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/design/) - How does it fit together?
* [Cluster](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/cluster/) - Setup a basic cluster
* [Load Balancer](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/loadbalancer/) Setup inbound access
* Snapshots (this page) - Automatically backup your persistent data
* [Helm](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/helm/) - Uber-recipes from fellow geeks
* [Traefik](https://geek-cookbook.funkypenguin.co.nz/)kubernetes/traefik/) - Traefik Ingress via Helm



## Chef's Notes

1. I've submitted [2 PRs](https://github.com/miracle2k/k8s-snapshots/pulls/funkypenguin) to the k8s-snapshots repo. The first [updates the README for GKE RBAC requirements](https://github.com/miracle2k/k8s-snapshots/pull/71), and the second [fixes a minor typo](https://github.com/miracle2k/k8s-snapshots/pull/74).