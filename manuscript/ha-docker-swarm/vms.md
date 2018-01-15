# Virtual Machines

Let's start building our cloud with virtual machines. You could use bare-metal machines as well, the configuration would be the same. Given that most readers (myself included) will be using virtual infrastructure, from now on I'll be referring strictly to VMs.

I chose the "[Atomic](https://www.projectatomic.io/)" CentOS/Fedora image for the VM layer because:

1. I want less responsibility for maintaining the system, including ensuring regular software updates and reboots. Atomic's idempotent nature means the OS is largely read-only, and updates/rollbacks are "atomic" (haha) procedures, which can be easily rolled back if required.
2. For someone used to administrating servers individually, Atomic is a PITA. You have to employ [tricky](https://spinningmatt.wordpress.com/2014/01/08/a-recipe-for-starting-cloud-images-with-virt-install/) [tricks](http://blog.oddbit.com/2015/03/10/booting-cloud-images-with-libvirt/) to get it to install in a non-cloud environment. It's not designed for tweaking or customizing beyond what cloud-config is capable of. For my purposes, this is good, because it forces me to change my thinking - to consider every daemon as a container, and every config as code, to be checked in and version-controlled. Atomic forces this thinking on you.
3. I want the design to be as "portable" as possible. While I run it on VPSs now, I may want to migrate it to a "cloud" provider in the future, and I'll want the most portable, reproducible design.


## Ingredients

!!! summary "Ingredients"
    3 x Virtual Machines, each with:

    * [ ] CentOS/Fedora Atomic
    * [ ] At least 1GB RAM
    * [ ] At least 20GB disk space (_but it'll be tight_)
    * [ ] Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)


## Preparation

### Install Virtual machines

1. Install / launch virtual machines.
2. The default username on CentOS atomic is "centos", and you'll have needed to supply your SSH key during the build process.

!!! tip
    If you're not using a platform with cloud-init support (i.e., you're building a VM manually, not provisioning it through a cloud provider), you'll need to refer to [trick #1][atomic-trick1] and [#2][atomic-trick2] for a means to override the automated setup, apply a manual password to the CentOS account, and enable SSH password logins.


### Prefer docker-latest

Run the following on each node to replace the default docker 1.12 with docker 1.13 (_which we need for swarm mode_):
```
systemctl disable docker --now
systemctl enable docker-latest --now
sed -i '/DOCKERBINARY/s/^#//g' /etc/sysconfig/docker
```


### Upgrade Atomic

Finally, apply any Atomic host updates, and reboot, by running: ```atomic host upgrade && systemctl reboot```.


### Permit connectivity between VMs

By default, Atomic only permits incoming SSH. We'll want to allow all traffic between our nodes, so add something like this to /etc/sysconfig/iptables:

```
# Allow all inter-node communication
-A INPUT -s 192.168.31.0/24 -j ACCEPT
```

And restart iptables with ```systemctl restart iptables```

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
[X] 3 x fresh atomic instances, at the latest releases,
    running Docker v1.13 (docker-latest)
```

## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
