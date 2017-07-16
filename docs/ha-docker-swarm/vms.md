# Introduction

Let's start building our cloud with virtual machines. You could use bare-metal machines as well, the configuration would be the same. Given that most readers (myself included) will be using virtual infrastructure, from now on I'll be referring strictly to VMs.

I chose the "[Atomic](https://www.projectatomic.io/)" CentOS/Fedora image for the VM layer because:

1. I want less responsibility for maintaining the system, including ensuring regular software updates and reboots. Atomic's idempotent nature means the OS is largely real-only, and updates/rollbacks are "atomic" (haha) procedures, which can be easily rolled back if required.
2. For someone used to administrating servers individually, Atomic is a PITA. You have to employ [tricky](atomic-trick2) [tricks](atomic-trick1) to get it to install in a non-cloud environment. It's not designed for tweaking or customizing beyond what cloud-config is capable of. For my purposes, this is good, because it forces me to change my thinking - to consider every daemon as a container, and every config as code, to be checked in and version-controlled. Atomic forces this thinking on you.
3. I want the design to be as "portable" as possible. While I run it on VPSs now, I may want to migrate it to a "cloud" provider in the future, and I'll want the most portable, reproducible design.

[atomic-trick1]:https://spinningmatt.wordpress.com/2014/01/08/a-recipe-for-starting-cloud-images-with-virt-install/
[atomic-trick2]:http://blog.oddbit.com/2015/03/10/booting-cloud-images-with-libvirt/

## Ingredients

3 x Virtual Machines, each with:

* CentOS/Fedora Atomic
* At least 1GB RAM
* At least 20GB disk space (_but it'll be tight_)
* Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)

## Preparation

### Install Virtual machines

1. Install / launch virtual machines.
2. The default username on CentOS atomic is "centos", and you'll have needed to supply your SSH key during the build process. If you're not using a platform with cloud-init support (i.e., you're building a VM manually, not provisioning it through a cloud provider), you'll need to refer to [trick #1][atomic-trick1] and [#2][atomic-trick2] for a means to override the automated setup, apply a manual password to the CentOS account, and enable SSH password logins.


### Upgrade Atomic

Run ```atomic host upgrade```, and reboot if necessary.


## Serving

After completing the above, you should have:

* [X] 3 fresh atomic instances, at the latest releases
* [X] A user belonging to the docker group for administration
