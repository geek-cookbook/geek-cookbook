---
description: Creating a Kubernetes cluster on k3s
---
# Deploy your cluster on k3s

If you're wanting to self-host your cluster, the simplest and most widely-supported approach is Rancher's [k3s](https://k3s.io/).

!!! summary "Ingredients"

    * [ ] One or more "modern" Linux hosts to serve as cluster masters. (*Using an odd number of masters is required for HA*). Additional steps are required for [Raspbian Buster](https://rancher.com/docs/k3s/latest/en/advanced/#enabling-legacy-iptables-on-raspbian-buster), [Alpine](https://rancher.com/docs/k3s/latest/en/advanced/#additional-preparation-for-alpine-linux-setup), or [RHEL/CentOS](https://rancher.com/docs/k3s/latest/en/advanced/#additional-preparation-for-red-hat-centos-enterprise-linux).

    Optional:

    * [ ] Additional hosts to serve as cluster agents (*assuming that not everybody gets to be a master!*)

## Preparation 

Ensure you have sudo access to your nodes, and that each node meets the [installation requirements](https://rancher.com/docs/k3s/latest/en/installation/installation-requirements/).

## Deploy k3s (one node only ever)

If you only want a single-node k3s cluster, then simply run the following to do the deployment:

```bash
MYSECRET=iambatman
curl -fL https://get.k3s.io | K3S_TOKEN=${MYSECRET} \
    sh -s - --disable traefik server
```

!!! question "Why no traefik?"
    k3s comes with the traefik ingress "built-in", so why not deploy it? Because we'd rather deploy it **later** (*if we even want it*), using the same [deployment strategy](/kubernetes/deployment/flux/) which we use with all of our other services, so that we can easily update/configure it.

## Deploy k3s (mooar nodes!)

### Deploy first master

You may only have one node now, but it's a good idea to prepare for future expansion by bootstrapping k3s in "embedded etcd" multi-master HA mode. Pick a secret to use for your server token, and run the following:

```bash
MYSECRET=iambatman
curl -fL https://get.k3s.io | K3S_TOKEN=${MYSECRET} \
    sh -s - --disable traefik --disable servicelb server --cluster-init
```

!!! question "y no servicelb?"
    K3s includes a [rudimentary load balancer](/kubernetes/loadbalancer/k3s/) which utilizes host ports to make a given port available on all nodes. If you plan to deploy one, and only one k3s node, then this is a viable configuration, and you can leave out the `--disable servicelb` text above. If you plan for more nodes and HA htough, then you're better off deploying [MetalLB](/kubernetes/loadbalancer/metallb/) to do "real" loadbalancing.

You should see output which looks something like this:

```bash
root@shredder:~# curl -fL https://get.k3s.io | K3S_TOKEN=${MYSECRET} \
>     sh -s - --disable traefik server --cluster-init
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100 27318  100 27318    0     0   144k      0 --:--:-- --:--:-- --:--:--  144k
[INFO]  Finding release for channel stable
[INFO]  Using v1.21.5+k3s2 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.21.5+k3s2/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.21.5+k3s2/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s
root@shredder:~#
```

Provided the last line of output says `Starting k3s` and not something more troublesome-sounding.. you have a cluster! Run `k3s kubectl get nodes -o wide` to confirm this, which has the useful side-effect of printing out your first master's IP address (*which we'll need for the next step*)

```bash
root@shredder:~# k3s kubectl get nodes -o wide
NAME       STATUS   ROLES                       AGE   VERSION        INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
shredder   Ready    control-plane,etcd,master   83s   v1.21.5+k3s2   192.168.39.201   <none>        Ubuntu 20.04.3 LTS   5.4.0-70-generic   containerd://1.4.11-k3s1
root@shredder:~#
```

!!! tip "^Z undo undo ..."
    Oops! Did you mess something up? Just run `k3s-uninstall.sh` to wipe all traces of K3s, and start over!

### Deploy other masters (optional)

Now that the first master is deploy, add additional masters (*remember to keep the total number of masters to an odd number*) by referencing the secret, and the IP address of the first master, on all the others:

```bash
MYSECRET=iambatman
curl -fL https://get.k3s.io | K3S_TOKEN=${MYSECRET} \
    sh -s - server --disable servicelb --server https://<IP OF FIRST MASTER>:6443
```

Run `k3s kubectl get nodes` to see your new master node make friends with the others:

```bash
root@shredder:~# k3s kubectl get nodes
NAME         STATUS   ROLES                       AGE     VERSION
bebop        Ready    control-plane,etcd,master   4m13s   v1.21.5+k3s2
rocksteady   Ready    control-plane,etcd,master   4m42s   v1.21.5+k3s2
shredder     Ready    control-plane,etcd,master   8m54s   v1.21.5+k3s2
root@shredder:~#
```

### Deploy agents (optional)

If you have more nodes which you want _not_ to be considered masters, then run the following on each. Note that the command syntax differs slightly from the masters (*which is why k3s deploys this as k3s-agent instead*)

```bash
MYSECRET=iambatman
curl -fL https://get.k3s.io | K3S_TOKEN=${MYSECRET} \
    K3S_URL=https://<IP OF FIRST MASTER>:6443 \
    sh -s -
```

!!! question "y no kubectl on agent?"
    If you tried to run `k3s kubectl` on an agent, you'll notice that it returns an error about `localhost:8080` being refused. This is **normal**, and it happens because agents aren't necessarily "trusted" to the same degree that masters are, and so the cluster admin credentials are **not** saved to the filesystem, as they are with masters.

!!! tip "^Z undo undo ..."
    Oops! Did you mess something up? Just run `k3s-agent-uninstall.sh` to wipe all traces of K3s agent, and start over!

## Release the kubectl!

k3s will have saved your kubeconfig file on the masters to `/etc/rancher/k3s/k3s.yaml`. This file contains the necessary config and certificates to administer your cluster, and should be treated with the same respect and security as your root password. To interact with the cluster, you need to tell the kubectl command where to find this `KUBECONFIG` file. There are a few ways to do this...

1. Prefix your `kubectl` commands with `k3s`. i.e., `kubectl cluster-info` becomes `k3s kubectl cluster-info`
2. Update your environment variables in your shell to set `KUBECONFIG` to `/etc/rancher/k3s/k3s.yaml`
3. Copy ``/etc/rancher/k3s/k3s.yaml` to `~/.kube/config`, which is the default location `kubectl` will look for

Examine your beautiful new cluster by running `kubectl cluster-info` [^1]

[^1]: Do you live in the CLI? Install the kubectl autocompletion for [bash](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/) or [zsh](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-zsh/) to make your life much easier!

--8<-- "recipe-footer.md"
