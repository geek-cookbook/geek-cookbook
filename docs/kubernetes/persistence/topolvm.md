---
title: TopoLVM - Capacity-aware LVM-based storage on Kubernetes
---
# TopoLVM on Kubernetes

TopoLVM is **like** [Local Path Provisioner](/kubernetes/persistence/local-path-provisioner/), in that it deals with local volumes specific to each Kubernetes node, but it offers more flexibility, and is more suited for a production deployment.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] A dedicated disk, or free LVM volume space, for provisioning volumes

Additional benefits offered by TopoLVM are:

* Volumes can by dynamically expanded
* The scheduler is capacity-aware, and can schedule pods to nodes with enough capacity for the pods' storage requirements
* Multiple storageclasses are supported, so you could, for example, create a storageclass for HDD-backed volumes, and another for SSD-backed volumes

## Preparation

### Volume Group

Finally you get to do something on your nodes without YAML or git, like a pre-GitOps, bare-metal-cavemonkey! :monkey_face:

On each node, you'll need an LVM Volume Group (VG) for TopoLVM to consume. The most straightforward to to arrange this is to dedicate a disk to TopoLVM, and create a dedicated PV and VG for it.

In brief, assuming `/dev/sdb` is the disk (*and it's unused*), you'd do the following to create a VG called `VG-topolvm`:

```bash
pvcreate /dev/sdb
vgcreate VG-topolvm /dev/sdb
```

!!! tip
    If you don't have a dedicated disk, you could try installing your OS using LVM partitioning, and leave some space unused, for TopoLVM to consume. Run `vgs` from an installed node to work out what the VG name is that the OS installer chose.

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/namespaces/namespace-topolvm.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: topolvm-system
```

### HelmRepository

Next, we need to define a HelmRepository (*a repository of helm charts*), to which we'll refer when we create the HelmRelease. We only need to do this once per-repository. In this case, we're using the official [TopoLVM helm chart](https://github.com/topolvm/topolvm/tree/main/charts/topolvm), so per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo:

```yaml title="/bootstrap/helmrepositories/helmrepository-topolvm.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: topolvm
  namespace: flux-system
spec:
  interval: 15m
  url: https://topolvm.github.io/topolvm
```

### Kustomization

Now that the "global" elements of this deployment (*Namespace and HelmRepository*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/topolvm`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-topolvm.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: topolvm--topolvm-system
  namespace: flux-system
spec:
  interval: 15m
  path: ./topolvm-system
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: topolvm-controller
      namespace: topolvm-system
    - apiVersion: apps/v1
      kind: DaemonSet
      name: topolvm-lvmd-0
      namespace: topolvm-system
    - apiVersion: apps/v1
      kind: DaemonSet
      name: topolvm-node
      namespace: topolvm-system
    - apiVersion: apps/v1
      kind: DaemonSet
      name: topolvm-scheduler
      namespace: topolvm-system
```

!!! question "What's with that screwy name?"
    > Why'd you call the kustomization `topolvm--topolvm-system`?

    I keep my file and object names as consistent as possible. In most cases, the helm chart is named the same as the namespace, but in some cases, by upstream chart or historical convention, the namespace is different to the chart name. TopoLVM is one of these - the helmrelease/chart name is `topolvm`, but the typical namespace it's deployed in is `topolvm-system`. (*Appending `-system` seems to be a convention used in some cases for applications which support the entire cluster*). To avoid confusion when I list all kustomizations with `kubectl get kustomization -A`, I give these oddballs a name which identifies both the helmrelease and the namespace.

### ConfigMap

Now we're into the topolvm-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/topolvm/topolvm/blob/main/charts/topolvm/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 spaces (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="/topolvm/configmap-topolvm-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: topolvm-helm-chart-value-overrides
  namespace: topolvm-system
data:
  values.yaml: |-
    # paste chart values.yaml (indented) here and alter as required>
```

--8<-- "kubernetes-why-full-values-in-configmap.md"

Then work your way through the values you pasted, and change any which are specific to your configuration. You might want to start off by changing the following to match the name of the [volume group you created above](#volume-group).[^1]

```yaml hl_lines="10-13"
lvmd:
  # lvmd.managed -- If true, set up lvmd service with DaemonSet.
  managed: true

  # lvmd.socketName -- Specify socketName.
  socketName: /run/topolvm/lvmd.sock

  # lvmd.deviceClasses -- Specify the device-class settings.
  deviceClasses:
    - name: ssd
      volume-group: myvg1
      default: true
      spare-gb: 10
```

### HelmRelease

Lastly, having set the scene above, we define the HelmRelease which will actually deploy TopoLVM into the cluster, with the config we defined above. I save this in my flux repo:

```yaml title="/topolvm/helmrelease-topolvm.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: topolvm
  namespace: topolvm-system
spec:
  chart:
    spec:
      chart: topolvm
      version: 3.x
      sourceRef:
        kind: HelmRepository
        name: topolvm
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: topolvm
  valuesFrom:
  - kind: ConfigMap
    name: topolvm-helm-chart-value-overrides
    valuesKey: values.yaml # This is the default, but best to be explicit for clarity
```

--8<-- "kubernetes-why-not-config-in-helmrelease.md"

## Serving

### Deploy TopoLVM

Having committed the above to your flux repository, you should shortly see a topolvm kustomization, and in the `topolvm-system` namespace, a bunch of pods:

```bash
demo@shredder:~$ kubectl get pods -n topolvm-system
NAME                                  READY   STATUS    RESTARTS   AGE
topolvm-controller-85698b44dd-65fd9   4/4     Running   0          133m
topolvm-controller-85698b44dd-dmncr   4/4     Running   0          133m
topolvm-lvmd-0-98h4q                  1/1     Running   0          133m
topolvm-lvmd-0-b29t8                  1/1     Running   0          133m
topolvm-lvmd-0-c5vnf                  1/1     Running   0          133m
topolvm-lvmd-0-hmmq5                  1/1     Running   0          133m
topolvm-lvmd-0-zfldv                  1/1     Running   0          133m
topolvm-node-6p4qz                    3/3     Running   0          133m
topolvm-node-7vdgt                    3/3     Running   0          133m
topolvm-node-mlp4x                    3/3     Running   0          133m
topolvm-node-sxtn5                    3/3     Running   0          133m
topolvm-node-xf265                    3/3     Running   0          133m
topolvm-scheduler-jlwsh               1/1     Running   0          133m
topolvm-scheduler-nj8nz               1/1     Running   0          133m
topolvm-scheduler-tg72z               1/1     Running   0          133m
demo@shredder:~$
```

### How do I know it's working?

So the controllers etc are running, but how do we know we can actually provision volumes?

#### Create PVC

Create a PVC, by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: topolvm-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: topolvm-provisioner
  resources:
    requests:
      storage: 128Mi
EOF
```

Examine the PVC by running `kubectl describe pvc topolvm-pvc`

#### Create Pod

Now create a pod to consume the PVC, by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: topolvm-test
spec:
  containers:
  - name: volume-test
    image: nginx:stable-alpine
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: topolvm-rocks
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: topolvm-rocks
    persistentVolumeClaim:
      claimName: topolvm-pvc
EOF
```

Examine the pod by running `kubectl describe pod topolvm-test`.

#### Clean up

Assuming that the pod is in a `Running` state, then TopoLVM is working!

Clean up your mess, little bare-metal-cave-monkey :monkey_face:, by running:

```bash
kubectl delete pod topolvm-test
kubectl delete pvc topolvm-pvc
```

### Troubleshooting

Are things not working as expected? Try one of the following to look for issues:

1. Watch the lvmd logs, by running `kubectl logs -f -n topolvm-system -l app.kubernetes.io/name=topolvm-lvmd`
2. Watch the node logs, by running `kubectl logs -f -n topolvm-system -l app.kubernetes.io/name=topolvm-node`
3. Watch the scheduler logs, by running `kubectl logs -f -n topolvm-system -l app.kubernetes.io/name=scheduler`
4. Watch the controller node logs, by running `kubectl logs -f -n topolvm-system -l app.kubernetes.io/name=controller`

{% include 'recipe-footer.md' %}

[^1]: This is where you'd add multiple Volume Groups if you wanted a storageclass per Volume Group
