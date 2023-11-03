---
description: Create a simple kubernetes cluster on EKS
title: Create your Kubernetes cluster on EKS
---

# A basic EKS cluster

If you're already in the AWS ecosystem, it may make sense for you to deploy your Kubernetes cluster using EKS. 

What follows are notes I made while establishing a very basic cluster to work on [OIDC authentication for EKS](/kubernetes/oidc-authentication/eks-authentik/) using [authentik][k8s/authentik].

## Ingredients

1. AWS CLI tools `awscli` and `eksctl`, configured for your IAM account
2. Some spare change :moneybag: on your AWS account for a few hours / days of EC2 for the underlying nodepool.

## Preparation

### Create cluster

Creating an EKS cluster is a one-line command. I ran `eksctl create cluster --name funkypenguin-authentik-test --region ap-southeast-2` to create my cluster.

It took 14 minutes to complete :man_facepalming:

### Setup EBS CSI driver

The default storageclass (gp2) didn't work for me, and I like storage based on CSI, so that I can use [Velero][velero] with [csi-snapshotter](/kubernetes/backup/csi-snapshots), so I added the [EBS CSI Driver](/kubernetes/persistence/aws-ebs/). This is optional if you don't care about CSI or persistent storage!

## Summary

Well, I'm done. This is probably the shortest recipe ever (*although 14 min is a comparatively long time, IMO, to deploy a simple cluster*). The links on this page to the various steps (OIDC, storage) will provide more detail on those particular configs.

{% include 'recipe-footer.md' %}
