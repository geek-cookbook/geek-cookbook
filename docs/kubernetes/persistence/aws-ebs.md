---
title: Support CSI VolumeSnapshots with snapshot-controller
description: Add CSI VolumeSnapshot support with snapshot support
values_yaml_url: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml
helm_chart_version: 2.24.x
helm_chart_name: aws-ebs-csi-driver
helm_chart_repo_name: aws-ebs-csi-driver
helm_chart_repo_url: 
helmrelease_name: aws-ebs-csi-driver
helmrelease_namespace: aws-ebs-csi-driver
kustomization_name: aws-ebs-csi-driver
slug: EBS CSI Driver
status: new
upstream: https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
github_repo: https://github.com/kubernetes-sigs/aws-ebs-csi-driver
---

# Install the AWS EBS CSI driver

The Amazon Elastic Block Store Container Storage Interface (CSI) Driver provides a CSI interface used by Container Orchestrators to manage the lifecycle of Amazon EBS volumes. It's a convenient way to consume EBS storage, which works consistently with other CSI-based tooling (*for example, you can dynamically expand and snapshot volumes*).

??? question "Tell me about the features..."

    * Static Provisioning - Associate an externally-created EBS volume with a PersistentVolume (PV) for consumption within Kubernetes.
    * Dynamic Provisioning - Automatically create EBS volumes and associated PersistentVolumes (PV) from PersistentVolumeClaims) (PVC). Parameters can be passed via a StorageClass for fine-grained control over volume creation.
    * Mount Options - Mount options could be specified in the PersistentVolume (PV) resource to define how the volume should be mounted.
    * NVMe Volumes - Consume NVMe volumes from EC2 Nitro instances.
    * Block Volumes - Consume an EBS volume as a raw block device.
    * Volume Snapshots - Create and restore snapshots taken from a volume in Kubernetes.
    * Volume Resizing - Expand the volume by specifying a new size in the PersistentVolumeClaim (PVC).

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) on [AWS EKS](/kubernetes/cluster/eks/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

### Setup IRSA

Before you deploy aws-ebs-csi-driver, it's necessary to perform some AWS IAM acronym-salad first :salad: ..

The CSI driver pods need access to your AWS account in order to provision EBS volumes. You **could** feed them with classic access key/secret keys, but a more "sophisticated" method is to use "[IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)", or IRSA.

IRSA lets you associate a Kubernetes service account with an IAM role, so instead of stashing access secrets somewhere in a namespace (*and in your GitOps repo[^1]*), you simply tell AWS "grant the service account `batcave-music` in the namespace `bat-ertainment` the ability to use my `streamToAlexa` IAM role.

Before we start, we have to use `eksctl` to generate an IAM OIDC provider for your cluster. I ran:

```bash
eksctl utils associate-iam-oidc-provider --cluster=funkypenguin-authentik-test --approve
```

(*It's harmless to run it more than once, if you already have an IAM OIDC provider associated, the command will just error*)

Once complete, I ran the following to grant the `aws-ebs-csi-driver` service account in the `aws-ebs-csi-driver` namespace the power to use the AWS-managed `AmazonEBSCSIDriverPolicy` policy, which exists for exactly this purpose:

```bash
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace aws-ebs-csi-driver \
    --cluster funkypenguin-authentik-test \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve
```

Part of what this does is **creates** the target service account in the target namespace - before we've deployed aws-ebs-csi-driver's HelmRelease.

Confirm it's worked by **describing** the serviceAccount - you should see an annotation indicating the role attached, like this:

```
Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::6831384437293:role/AmazonEKS_EBS_CSI_DriverRole
```

Now there's a problem - when the HelmRelease is installed, it'll try to create the serviceaccount, which we've just created. Flux's helm controller will then refuse to install the HelmRelease, because it can't "adopt" the service account as its own, under management.

The simplest fix I found for this was to run the following **before** reconciling the HelmRelease:

```bash
kubectl label serviceaccounts -n  aws-ebs-csi-driver \
    ebs-csi-controller-sa app.kubernetes.io/managed-by=Helm --overwrite
kubectl annotate serviceaccounts -n aws-ebs-csi-driver \
    ebs-csi-controller-sa meta.helm.sh/release-name=aws-ebs-csi-driver
kubectl annotate serviceaccounts -n aws-ebs-csi-driver\
    kube-system ebs-csi-controller-sa meta.helm.sh/release-namespace=kube-system
```

Once these labels/annotations are added, the HelmRelease will happily deploy, without altering the all-important annotation which lets the EBS driver work!

## Install {{ page.meta.slug }}!

Commit the changes to your flux repository, and either wait for the reconciliation interval, or force  a reconcilliation using `flux reconcile source git flux-system`. You should see the kustomization appear...

```bash
~ ❯ flux get kustomizations {{ page.meta.kustomization_name }}
NAME     	READY	MESSAGE                       	REVISION    	SUSPENDED
{{ page.meta.kustomization_name }}	True 	Applied revision: main/70da637	main/70da637	False
~ ❯
```

The helmrelease should be reconciled...

```bash
~ ❯ flux get helmreleases -n {{ page.meta.helmrelease_namespace }} {{ page.meta.helmrelease_name }}
NAME     	READY	MESSAGE                         	REVISION	SUSPENDED
{{ page.meta.helmrelease_name }}	True 	Release reconciliation succeeded	v{{ page.meta.helm_chart_version }}  	False
~ ❯
```

And you should have happy pods in the {{ page.meta.helmrelease_namespace }} namespace:

```bash
~ ❯ k get pods -n {{ page.meta.helmrelease_namespace }} -l app.kubernetes.io/name={{ page.meta.helmrelease_name }}
NAME                                  READY   STATUS    RESTARTS   AGE
ebs-csi-controller-77bddb4c95-2bzw5   5/5     Running   1 (10h ago)   37h
ebs-csi-controller-77bddb4c95-qr2hk   5/5     Running   0             37h
ebs-csi-node-4f8kz                    3/3     Running   0             37h
ebs-csi-node-fq8bn                    3/3     Running   0             37h
~ ❯
```

## How do I know it's working?

So the AWS EBS CSI driver is installed, but how do we know it's working, especially that IRSA voodoo?

### Check pod logs

First off, check the pod logs for any errors, by running:

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
```

If you see nasty errors about EBS access denied, then revisit the IRSA magic above. If not, proceed with the acid test :test_tube: below..

### Create resources

#### Create PVCs

Create a PVCs (*persistent volume claim*), by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: aws-ebs-csi-test
  labels:
    test: aws-ebs-csi
    funkypenguin-is: a-smartass  
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 128Mi
EOF
```

Examine the PVC, and note that it's in a pending state (*this is normal*):

```bash
kubectl get pvc -l test=aws-ebs-csi
```

#### Create Pod

Now create a pod to consume the PVC, by running:

```bash
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: aws-ebs-csi-test
  labels:
    test: aws-ebs-csi
    funkypenguin-is: a-smartass  
spec:
  containers:
  - name: volume-test
    image: nginx:stable-alpine
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: ebs-volume
      mountPath: /i-am-a-volume
    ports:
    - containerPort: 80
  volumes:
  - name: ebs-volume
    persistentVolumeClaim:
      claimName: aws-ebs-csi-test
EOF
```


Ensure the pods have started successfully (*this indicates the PVCs were correctly attached*) by running:

```bash
kubectl get pod -l test=aws-ebs-csi
```

#### Clean up

Assuming that the pod is in a `Running` state, then your EBS provisioning, and all the background AWS plumbing, worked!

Clean up your mess, little cloud-monkey :monkey_face:, by running:

```bash
kubectl delete pod -l funkypenguin-is=a-smartass
kubectl delete pvc -l funkypenguin-is=a-smartass
```

## Summary

What have we achieved? We're now able to persist data in our EKS cluster, and have left the door open for future options like snapshots, volume expansion, etc.

!!! summary "Summary"
    Created:

    * [X] AWS EBS CSI driver installed and tested in our EKS cluster
    * [X] Future support for [Velero][velero] with [csi-snapshots](/kubernetes/backup/csi-snapshots/), and volume expansion

{% include 'recipe-footer.md' %}

[^1]: Negated somewhat with [Sealed Secrets](/kubernetes/sealed-secrets/)
