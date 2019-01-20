# Kubernetes on DigitalOcean

IMO, the easiest Kubernetes cloud provider to experiment with is [DigitalOcean](https://m.do.co/c/e33b78ad621b) (_this is a referral link_). I've included instructions below to start a basic cluster.

![Kubernetes on Digital Ocean](/images/kubernetes-on-digitalocean.jpg)


## Ingredients

1. [DigitalOcean](https://m.do.co/c/e33b78ad621b) (_yes, this is a referral link, making me some 💰_) account, either linked to a credit card or (_my preference for a trial_) topped up with $5 credit from PayPal.

## Preparation

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
```
[davidy:~/Downloads] 130 % kubectl --kubeconfig=penguins-are-the-sexiest-geeks-kubeconfig.yaml get nodes
NAME                  STATUS    ROLES     AGE       VERSION
festive-merkle-8n9e   Ready     <none>    20s       v1.13.1
[davidy:~/Downloads] %
```

In the example above, my nodes were being deployed. Repeat the command to see your nodes spring into existence:

```
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

## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
