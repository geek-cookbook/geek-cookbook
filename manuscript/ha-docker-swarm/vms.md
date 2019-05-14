# Virtual Machines

Let's start building our cluster. You can use either bare-metal machines or virtual machines - the configuration would be the same. Given that most readers (myself included) will be using virtual infrastructure, from now on I'll be referring strictly to VMs.

!!! note
    In 2017, I **initially** chose the "[Atomic](https://www.projectatomic.io/)" CentOS/Fedora image for the swarm hosts, but later found its outdated version of Docker to be problematic with advanced features like GPU transcoding (in [Plex](/recipes/plex/)), [Swarmprom](/recipes/swarmprom/), etc. In the end, I went mainstream and simply preferred a modern Ubuntu installation.

## Ingredients

!!! summary "Ingredients"
    3 x Virtual Machines, each with:

    * [ ] A mainstream Linux OS (*tested on either [CentOS](https://www.centos.org) 7+ or [Ubuntu](http://releases.ubuntu.com) 16.04+*)
    * [ ] At least 2GB RAM
    * [ ] At least 20GB disk space (_but it'll be tight_)
    * [ ] Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)


## Preparation

### Install Virtual machines

1. Install / launch virtual machines.
2. The default username on CentOS atomic is "centos", and you'll have needed to supply your SSH key during the build process.

!!! tip
    If you're not using a platform with cloud-init support (i.e., you're building a VM manually, not provisioning it through a cloud provider), you'll need to refer to [trick #1](https://spinningmatt.wordpress.com/2014/01/08/a-recipe-for-starting-cloud-images-with-virt-install/) and [trick #2](http://blog.oddbit.com/2015/03/10/booting-cloud-images-with-libvirt/) for a means to override the automated setup, apply a manual password to the CentOS account, and enable SSH password logins.

### Permit connectivity between hosts

Most modern Linux distributions include firewall rules which only only permit minimal required incoming connections (like SSH). We'll want to allow all traffic between our nodes. The steps to achieve this in CentOS/Ubuntu are a little different...

#### CentOS

Add something like this to `/etc/sysconfig/iptables`:

```
# Allow all inter-node communication
-A INPUT -s 192.168.31.0/24 -j ACCEPT
```

And restart iptables with ```systemctl restart iptables```

#### Ubuntu

Install the (*non-default*) persistent iptables tools, by running `apt-get install iptables-persistent`, establishing some default rules (*dkpg will prompt you to save current ruleset*), and then add something like this to `/etc/iptables/rules.v4`:

```
# Allow all inter-node communication
-A INPUT -s 192.168.31.0/24 -j ACCEPT
```

And refresh your running iptables rules with `iptables-restore < /etc/iptables/rules.v4`

### Enable host resolution

Depending on your hosting environment, you may have DNS automatically setup for your VMs. If not, it's useful to set up static entries in /etc/hosts for the nodes. For example, I setup the following:

```
192.168.31.11   ds1     ds1.funkypenguin.co.nz
192.168.31.12   ds2     ds2.funkypenguin.co.nz
192.168.31.13   ds3     ds3.funkypenguin.co.nz
```

### Set timezone

Set your local timezone, by running:

```
ln -sf /usr/share/zoneinfo/<your timezone> /etc/localtime
```

## Serving

After completing the above, you should have:

```
[X] 3 x fresh linux instances, ready to become swarm nodes
```

## Chef's Notes

### Tip your waiter (support me) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
