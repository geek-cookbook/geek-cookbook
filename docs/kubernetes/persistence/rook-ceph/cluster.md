---
title: Deploy Rook Ceph's operater-managed Cluster for Persistent Storage in Kubernetes
description: Step #2 - Having the operator available, now we deploy the ceph cluster itself
---

# Persistent storage in Kubernetes with Rook Ceph / CephFS - Cluster

[Ceph](https://docs.ceph.com/en/quincy/) is a highly-reliable, scalable network storage platform which uses individual disks across participating nodes to provide fault-tolerant storage.

[Rook](https://rook.io) provides an operator for Ceph, decomposing the [10-year-old](https://en.wikipedia.org/wiki/Ceph_(software)#Release_history), at-time-arcane, platform into cloud-native components, created declaratively, whose lifecycle is managed by an operator.

In the [previous recipe](/kubernetes/persistence/rook-ceph/operator/), we deployed the operator, and now to actually deploy a Ceph cluster, we need to deploy a custom resource (*a "CephCluster"*), which will instruct the operator on we'd like our cluster to be deployed.

We'll end up with multilpe storageClasses which we can use to allocate storage to pods from either Ceph RBD (*block storage*), or CephFS (*a mounted filesystem*). In many cases, CephFS is a useful choice, because it can be mounted from more than one pod **at the same time**, which makes it suitable for apps which need to share access to the same data ([NZBGet][nzbget], [Sonarr][sonarr], and [Plex][plex], for example)

## Rook Ceph Cluster requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] Rook Ceph's [Operator](/kubernetes/persistence/rook-ceph/operator/)

## Preparation

### Namespace

We already deployed a `rook-ceph` namespace when deploying the Rook Ceph [Operator](/kubernetes/persistence/rook-ceph/operator/), so we don't need to create this again :thumbsup: [^1]

### HelmRepository

Likewise, we'll install the `rook-ceph-cluster` helm chart from the same Rook-managed repository as we did the `rook-ceph` (operator) chart, so we don't need to create a new HelmRepository.

### Kustomization

We do, however, need a separate Kustomization for rook-ceph-cluster, telling flux to deploy any YAMLs found in the repo at `/rook-ceph-cluster`. I create this example Kustomization in my flux repo:

!!! question "Why a separate Kustomization if both are needed for rook-ceph?"
    While technically we **could** use the same Kustomization to deploy both `rook-ceph` and `rook-ceph-cluster`, we'd run into dependency issues. It's simpler and cleaner to deploy `rook-ceph` first, and then list it as a dependency for `rook-ceph-cluster`.

```yaml title="/bootstrap/kustomizations/kustomization-rook-ceph-cluster.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: rook-ceph-cluster--rook-ceph
  namespace: flux-system
spec:
  dependsOn: 
  - name: "rook-ceph" # (1)!
  interval: 30m
  path: ./rook-ceph-cluster
  prune: true # remove any elements later removed from the above path
  timeout: 10m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
```

1. Note that we use the `spec.dependsOn` to ensure that this Kustomization is only applied **after** the rook-ceph operator is deployed and operational. This ensures that the necessary CRDs are in place, and avoids a dry-run error on the reconciliation.

--8<-- "premix-cta-kubernetes.md"

### ConfigMap

Now we're into the app-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/rook/rook/blob/master/deploy/charts/rook-ceph-cluster/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="/rook-ceph-cluster/configmap-rook-ceph-cluster-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: rook-ceph-cluster-helm-chart-value-overrides
  namespace: rook-ceph
data:
  values.yaml: |-  # (1)!
    # <upstream values go here>
```

1. Paste in the contents of the upstream `values.yaml` here, intended 4 spaces, and then change the values you need as illustrated below.

Here are some suggested changes to the defaults which you should consider:

```yaml
toolbox:
  enabled: true # (1)!
monitoring:
  # enabling will also create RBAC rules to allow Operator to create ServiceMonitors
  enabled: true # (2)!
  # whether to create the prometheus rules
  createPrometheusRules: true # (3)!
pspEnable: false # (4)!
ingress:
  dashboard: {} # (5)!
```

1. It's useful to have a "toolbox" pod to shell into to run ceph CLI commands
2. Consider enabling if you already have Prometheus installed
3. Consider enabling if you already have Prometheus installed
4. PSPs are deprecated, and will eventually be removed in Kubernetes 1.25, at which point this will cause breakage.  
5. Customize the ingress configuration for your dashboard

Further to the above, decide which disks you want to dedicate to Ceph, and add to the `cephClusterSpec` section.

The default configuration (below) will cause the operator to use any un-formatted disks found on any of your nodes. If this is what you **want** to happen, then you don't need to change anything.

```yaml
cephClusterSpec:
  storage: # cluster level storage configuration and selection
    useAllNodes: true
    useAllDevices: true
```

If you'd rather be a little more selective / declarative about which disks are used in a homogenous cluster, you could consider using `deviceFilter`, like this:

```yaml
cephClusterSpec:
  storage: # cluster level storage configuration and selection
    useAllNodes: true
    useAllDevices: false
    deviceFilter: sdc #(1)!
```

1. A regex to use to filter target devices found on each node

If your cluster nodes are a little more snowflakey :snowflake:, here's a complex example:

```yaml
cephClusterSpec:
  storage: # cluster level storage configuration and selection
    useAllNodes: false
    useAllDevices: false
    nodes:
    - name: "teeny-tiny-node"
      deviceFilter: "." #(1)!
    - name: "bigass-node"
      devices:
      - name: "/dev/disk/by-path/pci-0000:01:00.0-sas-exp0x500404201f43b83f-phy11-lun-0" #(2)!
        config:
          metadataDevice: "/dev/osd-metadata/11"
      - name: "nvme0n1" #(3)!
      - name: "nvme1n1"
```

1. Match any devices found on this node
2. Match a very-specific device path, and pair this device with a faster device for OSD metadata
3. Match devices with simple regex string matches

### HelmRelease

Finally, having set the scene above, we define the HelmRelease which will actually deploy the rook-ceph operator into the cluster. I save this in my flux repo:

```yaml title="/rook-ceph-cluster/helmrelease-rook-ceph-cluster.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: rook-ceph-cluster
  namespace: rook-ceph
spec:
  chart:
    spec:
      chart: rook-ceph-cluster
      version: 1.9.x
      sourceRef:
        kind: HelmRepository
        name: rook-release
        namespace: flux-system
  interval: 30m
  timeout: 10m
  install:
    remediation:
      retries: 3
  upgrade:
    remediation:
      retries: -1 # keep trying to remediate
    crds: CreateReplace # Upgrade CRDs on package update
  releaseName: rook-ceph-cluster
  valuesFrom:
  - kind: ConfigMap
    name: rook-ceph-cluster-helm-chart-value-overrides
    valuesKey: values.yaml # (1)!
```

1. This is the default, but best to be explicit for clarity

## Install Rook Ceph Operator!

Commit the changes to your flux repository, and either wait for the reconciliation interval, or force  a reconcilliation using `flux reconcile source git flux-system`. You should see the kustomization appear...

```bash
~ ❯ flux get kustomizations rook-ceph-cluster
NAME             	READY	MESSAGE                       	REVISION    	SUSPENDED
rook-ceph-cluster	True 	Applied revision: main/345ee5e	main/345ee5e	False
~ ❯
```

The helmrelease should be reconciled...

```bash
~ ❯ flux get helmreleases -n rook-ceph rook-ceph 
NAME             	READY	MESSAGE                         	REVISION	SUSPENDED
rook-ceph-cluster	True 	Release reconciliation succeeded	v1.9.9  	False
~ ❯
```

And you should have happy rook-ceph operator pods:

```bash
~ ❯ k get pods -n rook-ceph -l app=rook-ceph-operator
NAME                                  READY   STATUS    RESTARTS   AGE
rook-ceph-operator-7c94b7446d-nwsss   1/1     Running   0          5m14s
~ ❯
```

To watch the operator do its magic, you can tail its logs, using:

```bash
k logs -n rook-ceph -f -l app=rook-ceph-operator
```

You can **get** or **describe** the status of your cephcluster:

```bash
~ ❯ k get cephclusters.ceph.rook.io  -n rook-ceph
NAME        DATADIRHOSTPATH   MONCOUNT   AGE     PHASE   MESSAGE                        HEALTH      EXTERNAL
rook-ceph   /var/lib/rook     3          6d22h   Ready   Cluster created successfully   HEALTH_OK
~ ❯
```

### How do I know it's working?

So we have a ceph cluster now, but how do we know we can actually provision volumes?

#### Create PVCs

Create two ceph-block PVCs (*persistent volume claim*), by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-block-pvc-1
  labels:
    test: ceph
    funkypenguin-is: a-smartass  
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-block
  resources:
    requests:
      storage: 128Mi
EOF
```

And:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-block-pvc-2
  labels:
    test: ceph
    funkypenguin-is: a-smartass  
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ceph-block
  resources:
    requests:
      storage: 128Mi
EOF
```

Now create a ceph-filesystem (RWX) PVC, by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-filesystem-pvc
  labels:
    test: ceph
    funkypenguin-is: a-smartass  
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ceph-filesystem
  resources:
    requests:
      storage: 128Mi
EOF
```

Examine the PVCs by running:

```bash
kubectl get pvc -l test=ceph
```

#### Create Pod

Now create pods to consume the PVCs, by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: ceph-test-1
  labels:
    test: ceph
    funkypenguin-is: a-smartass  
spec:
  containers:
  - name: volume-test
    image: nginx:stable-alpine
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: ceph-block-is-rwo
      mountPath: /rwo
    - name: ceph-filesystem-is-rwx
      mountPath: /rwx
    ports:
    - containerPort: 80
  volumes:
  - name: ceph-block-is-rwo
    persistentVolumeClaim:
      claimName: ceph-block-pvc-1
EOF
```

And:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: ceph-test-2
  labels:
    test: ceph
    funkypenguin-is: a-smartass
spec:
  containers:
  - name: volume-test
    image: nginx:stable-alpine
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: ceph-block-is-rwo
      mountPath: /rwo
    - name: ceph-filesystem-is-rwx
      mountPath: /rwx
    ports:
    - containerPort: 80
  volumes:
  - name: ceph-block-is-rwo
    persistentVolumeClaim:
      claimName: ceph-block-pvc-2
  - name: ceph-filesystem-is-rwx
    persistentVolumeClaim:
      claimName: ceph-filesystem-pvc     
EOF
```

Ensure the pods have started successfully (*this indicates the PVCs were correctly attached*) by running:

```bash
kubectl get pod -l test=ceph
```

#### Clean up

Assuming that the pod is in a `Running` state, then TopoLVM is working!

Clean up your mess, little bare-metal-cave-monkey :monkey_face:, by running:

```bash
kubectl delete pod -l funkypenguin-is=a-smartass
kubectl delete pvc -l funkypenguin-is=a-smartass #(1)!
```

1. Label selectors are powerful!

### View Ceph Dashboard

Assuming you have an Ingress Controller setup, and you've either picked a default IngressClass, or defined the dashboard ingress appropriately, you should be able to access your Ceph Dashboard, at the URL identified by the ingress (*this is a good opportunity to check that the ingress deployed correctly*):

```bash
~ ❯ k get ingress -n rook-ceph
NAME                      CLASS   HOSTS                          ADDRESS        PORTS     AGE
rook-ceph-mgr-dashboard   nginx   rook-ceph.batcave.awesome.me   172.16.237.1   80, 443   177d
~ ❯
```

The dashboard credentials are automatically generated for you by the operator, and stored in a Kubernetes secret. To retrieve your credentials, run:

```bash
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o \
jsonpath="{['data']['password']}" | base64 --decode && echo
```

## Summary

What have we achieved? We're half-way to getting a ceph cluster, having deployed the operator which will manage the lifecycle of the [ceph cluster](/kubernetes/persistence/rook-ceph/cluster/) we're about to create!

!!! summary "Summary"
    Created:

    * [X] Ceph cluster has been deployed
    * [X] StorageClasses are available so that the cluster storage can be consumed by your pods
    * [X] Pretty graphs are viewable in the Ceph Dashboard

--8<-- "recipe-footer.md"

[^1]: Unless you **wanted** to deploy your cluster components in a separate namespace to the operator, of course!
