---
title: How to choose a managed Kubernetes cluster vs build your own
description: So you want to play with Kubernetes? The first decision you need to make is how your cluster will run. Do you choose (and pay a premium for) a managed Kubernetes cloud provider, or do you "roll your own" with kubeadm on bare-metal, VMs, or k3s?
---
# Kubernetes Cluster

There are an ever-increasing amount of ways to deploy and run Kubernetes. The primary distinction to be aware of is whether to fork out for a managed Kubernetes instance or not. Managed instances have some advantages, which I'll detail below, but these come at additional cost.

## Managed (Cloud Provider)

### Popular Options

Popular options are:

* [DigitalOcean](/kubernetes/cluster/digitalocean/)
* Google Kubernetes Engine (GKE)
* Amazon Elastic Kubernetes Service (EKS)
* Azure Kubernetes Service (AKS)

### Upgrades

A managed Kubernetes provider will typically provide a way to migrate to pre-tested and trusted versions of Kuberenetes, as they're released and then tested. This [doesn't mean that upgrades will be trouble-free](https://www.digitalocean.com/community/tech_talks/20-000-upgrades-later-lessons-from-a-year-of-managed-kubernetes-upgrades), but they're likely to be less of a PITA. With Kubernetes' 4-month release cadence, you'll want to keep an eye on updates, and avoid becoming too out-of-date.

### Horizontal Scaling

One of the key drawcards for Kubernetes is horizonal scaling. You want to be able to expand/contract your cluster as your workloads change, even if just for one day a month. Doing this on your own hardware is.. awkward.

### Load Balancing

Even if you had enough hardware capacity to handle any unexpected scaling requirements, ensuring that traffic can reliably reach your cluster is a complicated problem. You need to present a "virtual" IP for external traffic to ingress the cluster on. There are popular solutions to provide LoadBalancer services to a self-managed cluster (*i.e., [MetalLB](/kubernetes/loadbalancer/metallb/)*), but they do represent extra complexity, and won't necessarily be resilient to outages outside of the cluster (*network devices, power, etc*).

### Storage

Cloud providers make it easy to connect their storage solutions to your cluster, but you'll pay as you scale, and in most cases, I/O on cloud block storage is throttled along with your provisioned size. (*So a 1Gi volume will have terrible IOPS compared to a 100Gi volume*)

### Services

Some things just "work better" in a cloud provider environment. For example, to run a highly available Postgres instance on Kubernetes requires at least 3 nodes, and 3 x storage, plus manual failover/failback in the event of an actual issue. This can represent a huge cost if you simply need a PostgreSQL database to provide (*for example*) a backend to an authentication service like Keycloak. Cloud providers will have a range of managed database solutions which will cost far less than do-it-yourselfing, and integrate easily and securely into their kubernetes offerings.

### Summary

Go with a managed provider if you want your infrastructure to be resilient to your own hardware/connectivity issues. I.e., there's a material impact to a power/network/hardware outage, and the cost of the managed provider is less than the cost of an outage.

## DIY (Cloud Provider, Bare Metal, VMs)

### Popular Options

Popular options are:

* Rancher's K3s
* Ubuntu's Charmed Kubernetes

### Flexible

With self-hosted Kubernetes, you're free to mix/match your configuration as you see fit. You can run a single k3s node on a raspberry pi, or a fully HA pi-cluster, or a handful of combined master/worker nodes on a bunch of proxmox VMs, or on plain bare-metal.

### Education

You'll learn more about how to care for and feed your cluster if you build it yourself. But you'll definately spend more time on it, and it won't always be when you expect!

### Summary

Go with a self-hosted cluster if you want to learn more, you'd rather spend time than money, or you've already got significant investment in local infructure and technical skillz.

{% include 'recipe-footer.md' %}
