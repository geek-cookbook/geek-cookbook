# Introduction

We start building our cloud with virtual machines. You could use bare-metal machines as well, the configuration would be the same. Given that most readers (myself included) will be using virtual infrastructure, from now on I'll be referring strictly to VMs.

## Ingredients

3 x Virtual Machines, each with:
* CentOS/Fedora Atomic
* At least 1GB RAM
* At least 20GB disk space (but it'll be tight)
* Connectivity to each other within the same subnet, and on a low-latency link (i.e., no WAN links)

## Preparation

### Install Virtual machines

1. Install Virtual machines
2. Setup super-user access for your admin user, as a member of the "docker" group


I chose the "Atomic" CentOS/Fedora image because:

1. I want less responsibility for maintaining the system, including ensuring regular software updates and reboots. Atomic's idempotent nature means the OS is largely real-only, and updates/rollbacks are "atomic" (haha) procedures, which can be easily rolled back if required.
2. For someone used to administrating servers individually, Atomic is a PITA. You have to employ [tricky](http://blog.oddbit.com/2015/03/10/booting-cloud-images-with-libvirt/) [tricks](https://spinningmatt.wordpress.com/2014/01/08/a-recipe-for-starting-cloud-images-with-virt-install/) to get it to install in a non-cloud environment. It's not designed for tweaking or customizing beyond what cloud-config is capable of. For my purposes, this is good, because it forces me to change my thinking - to consider every daemon as a container, and every config as code, to be checked in and version-controlled. Atomic forces this thinking on you.
3. I want the design to be as "portable" as possible. While I run it on VPSs now, I may want to migrate it to a "cloud" provider in the future, and I'll want the most portable, reproducible design.


atomic host upgrade
