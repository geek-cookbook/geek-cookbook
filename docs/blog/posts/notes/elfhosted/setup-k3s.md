---
date: 2023-06-11
categories:
  - note
tags:
  - elfhosted
title: Kubernetes on Hetzner dedicated server
description: How to setup and secure a bare-metal Kubernetes infrastructure on Hetzner dedicated servers
draft: true
---

# Kubernetes (K3s) on Hetzner

In this post, we continue our adventure setting up an app hosting platform running on Kubernetes.

--8<-- "blog-series-elfhosted.md"

My two physical servers were "delivered" (to my inbox), along with instructions re SSHing to the "rescueimage" environment, which looks like this:



<!-- more -->

--8<-- "what-is-elfhosted.md"


## Secure nodes

Per the K3s docs, there are some local firewall requirements for K3s server/worker nodes:

https://docs.k3s.io/installation/requirements#inbound-rules-for-k3s-server-nodes



It's aliiive!

```
root@fairy01 ~ # kubectl get nodes
NAME      STATUS   ROLES                       AGE   VERSION
elf01     Ready    <none>                      15s   v1.26.5+k3s1
fairy01   Ready    control-plane,etcd,master   96s   v1.26.5+k3s1
root@fairy01 ~ #
```

Now install flux, according to this documentedb bootstrap process...


https://metallb.org/configuration/k3s/


Prepare for Longhorn's [NFS schenanigans](https://longhorn.io/docs/1.4.2/deploy/install/#installing-nfsv4-client):

```
apt-get -y install nfs-common tuned
```

Performance mode!

`tuned-adm profile throughput-performance`

Taint the master(s)

```
kubectl taint node fairy01 node-role.kubernetes.io/control-plane=true:NoSchedule
```


```
increase max pods:
https://stackoverflow.com/questions/65894616/how-do-you-increase-maximum-pods-per-node-in-k3s

https://gist.github.com/rosskirkpat/57aa392a4b44cca3d48dfe58b5716954

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --kubelet-arg=config=/etc/rancher/k3s/kubelet-server.config --disable traefik  --disable servicelb --flannel-backend=wireguard-native --flannel-iface=enp0s31f6.4000 --kube-controller-manager-arg=node-cidr-mask-size=22 --kubelet-arg=max-pods=500 --node-taint node-role.kubernetes.io/control-plane --prefer-bundled-bin" sh -
```

create secondary masters:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --kubelet-arg=config=/etc/rancher/k3s/kubelet-server.config --disable traefik  --disable servicelb --flannel-backend=wireguard-native --flannel-iface=enp0s31f6.4000 --kube-controller-manager-arg=node-cidr-mask-size=22 --kubelet-arg=max-pods=500 --node-taint node-role.kubernetes.io/control-plane --prefer-bundled-bin" sh -

```


```
mkdir -p /etc/rancher/k3s/
cat << EOF >> /etc/rancher/k3s/kubelet-server.config
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
maxPods: 500
EOF
```




and on the worker


Ensure that `/etc/rancher/k3s` exists, to hold our kubelet custom configuration file:

```bash
mkdir -p /etc/rancher/k3s/
cat << EOF >> /etc/rancher/k3s/kubelet-server.config
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
maxPods: 500
EOF
```

Get [token](https://docs.k3s.io/cli/token) from `/var/lib/rancher/k3s/server/token` on the server, and prepare the environment like this:
```bash
export K3S_TOKEN=<token from master>
export K3S_URL=https://<ip of master>:6443
```

Now join the worker using

```
curl -sfL https://get.k3s.io |  INSTALL_K3S_EXEC="agent --flannel-iface=eno1.4000 --kubelet-arg=config=/etc/rancher/k3s/kubelet-server.config --prefer-bundled-bin" sh -

```


```
flux bootstrap github \
  --owner=geek-cookbook \ 
  --repository=geek-cookbook/elfhosted-flux \
  --path bootstrap
  ```

```
root@fairy01:~# kubectl -n sealed-secrets create secret tls elfhosted-expires-june-2033 \
  --cert=mytls.crt --key=mytls.key
secret/elfhosted-expires-june-2033 created
root@fairy01:~# kubectl kubectl -n sealed-secrets label secret^C
root@fairy01:~# kubectl -n sealed-secrets label secret elfhosted-expires-june-2033 sealedsecrets.bitnami.com/sealed-secrets-key=active
secret/elfhosted-expires-june-2033 labeled
root@fairy01:~# kubectl rollout restart -n sealed-secrets deployment sealed-secrets
deployment.apps/sealed-secrets restarted
```

increase watchers (jellyfin)
echo fs.inotify.max_user_watches=2097152 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

echo 512 > /proc/sys/fs/inotify/max_user_instances

on dwarves

k taint node dwarf01.elfhosted.com  node-role.elfhosted.com/node=storage:NoSchedule

