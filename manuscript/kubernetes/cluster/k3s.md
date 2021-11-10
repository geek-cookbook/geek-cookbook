# Deploy your cluster on k3s

If you're wanting to self-host your cluster, the simplest and most widely-supported approach is Rancher's [k3s](https://k3s.io/).

!!! summary "Ingredients"

    * [ ] One or more "modern" Linux hosts to serve as cluster masters. (*Using an odd number of masters is required for HA*). Additional steps are required for [Raspbian Buster](https://rancher.com/docs/k3s/latest/en/advanced/#enabling-legacy-iptables-on-raspbian-buster), [Alpine](https://rancher.com/docs/k3s/latest/en/advanced/#additional-preparation-for-alpine-linux-setup), or [RHEL/CentOS](https://rancher.com/docs/k3s/latest/en/advanced/#additional-preparation-for-red-hat-centos-enterprise-linux).

    Optional:

    * [ ] Additional hosts to serve as cluster agents (*assuming that not everybody gets to be a master!*)

## Single node k3s cluster

```bash
K3S_TOKEN=SECRET k3s server --cluster-init
```

## Highly Availble k3s cluster

```bash
K3S_TOKEN=SECRET k3s server --cluster-init
```

### Create DigitalOcean Account

Create a project, and then from your project page, click **Manage** -> **Kubernetes (LTD)** in the left-hand panel:

![Kubernetes on Digital Ocean Screenshot #1](/images/kubernetes-on-digitalocean-screenshot-1.png)

Until DigitalOcean considers their Kubernetes offering to be "production ready", you'll need the additional step of clicking on **Enable Limited Access**:

![Kubernetes on Digital Ocean Screenshot #2](/images/kubernetes-on-digitalocean-screenshot-2.png)

The _Enable Limited Access_ button changes to read _Create a Kubernetes Cluster_ . Cleeeek it:

![Kubernetes on Digital Ocean Screenshot #3](/images/kubernetes-on-digitalocean-screenshot-3.png)

When prompted, choose some defaults for your first node pool (_your pool of "compute" resources for your cluster_), and give it a name. In more complex deployments, you can use this concept of "node pools" to run certain applications (_like an inconsequential nightly batch job_) on a particular class of compute instance (_such as cheap, preemptible instances_)

![Kubernetes on Digital Ocean Screenshot #4](/images/kubernetes-on-digitalocean-screenshot-4.png)

That's it! Have a sip of your 🍷, a bite of your :cheese:, and wait for your cluster to build. While you wait, follow the instructions to setup kubectl (if you don't already have it)

![Kubernetes on Digital Ocean Screenshot #5](/images/kubernetes-on-digitalocean-screenshot-5.png)

DigitalOcean will provide you with a "kubeconfig" file to use to access your cluster. It's at the bottom of the page (_illustrated below_), and easy to miss (_in my experience_).

![Kubernetes on Digital Ocean Screenshot #6](/images/kubernetes-on-digitalocean-screenshot-6.png)

## Release the kubectl!

Save your kubeconfig file somewhere, and test it our by running ```kubectl --kubeconfig=<PATH TO KUBECONFIG> get nodes```

Example output:

```bash
[davidy:~/Downloads] 130 % kubectl --kubeconfig=penguins-are-the-sexiest-geeks-kubeconfig.yaml get nodes
NAME                  STATUS    ROLES     AGE       VERSION
festive-merkle-8n9e   Ready     <none>    20s       v1.13.1
[davidy:~/Downloads] %
```

In the example above, my nodes were being deployed. Repeat the command to see your nodes spring into existence:

```bash
[davidy:~/Downloads] % kubectl --kubeconfig=penguins-are-the-sexiest-geeks-kubeconfig.yaml get nodes
NAME                  STATUS    ROLES     AGE       VERSION
festive-merkle-8n96   Ready     <none>    6s        v1.13.1
festive-merkle-8n9e   Ready     <none>    34s       v1.13.1
[davidy:~/Downloads] %

[davidy:~/Downloads] % kubectl --kubeconfig=penguins-are-the-sexiest-geeks-kubeconfig.yaml get nodes
NAME                  STATUS    ROLES     AGE       VERSION
festive-merkle-8n96   Ready     <none>    30s       v1.13.1
festive-merkle-8n9a   Ready     <none>    17s       v1.13.1
festive-merkle-8n9e   Ready     <none>    58s       v1.13.1
[davidy:~/Downloads] %
```

That's it. You have a beautiful new kubernetes cluster ready for some action!


[^1]: Ok, yes, there's not much you can do with your cluster _yet_. But stay tuned, more Kubernetes fun to come!

--8<-- "recipe-footer.md"
