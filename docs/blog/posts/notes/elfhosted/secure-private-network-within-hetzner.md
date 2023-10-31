---
date: 2023-06-09
categories:
  - note
tags:
  - elfhosted
title: Baby steps towards ElfHosted
description: Every journey has a beginning. This is the beginning of the ElfHosted journey
draft: true
---

Securing the Hetzner environment

Before building out our Kubernetes cluster, I wanted to secure the environment a little. On Hetzner, each server is assigned a public IP from a huge pool, and is directly accessible over the internet. This provides quick access for administration, but before building out our controlplane, I wanted to lock down access.

## Requirements

* [x] Kubernetes worker/controlplane nodes are privately addressed
* [x] Control plane (API) will be accessible only internally
* [x] Nodes can be administered directly on their private address range

## The bastion VM

I created a small cloud "ampere" VM using Hetzner's cloud console. These cloud VMs are provisioned separately from dedicated servers, but it's possible to interconnect them with dedicated servers using vSwitches/subnets (bascically VLANs)

I needed a "bastion" host - a small node (probably a VM), which I could secure and then use for further ingress into my infrastructure.

## Connecting Bastion VM to dedicated VMs

I 

https://tailscale.com/kb/1150/cloud-hetzner/


https://tailscale.com/kb/1077/secure-server-ubuntu-18-04/


https://docs.hetzner.com/cloud/networks/connect-dedi-vswitch

```bash
 tailscale up --advertise-routes 10.0.42.0/24
 ```

sysctl edit

```bash
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]

# Forward traffic through eth0 - Change to match you out-interface
-A POSTROUTING -s <your tailscale ip> -j MASQUERADE

# don't delete the 'COMMIT' line or these nat table rules won't
# be processed
COMMIT
```


hetzner_cloud_console_subnet_routes.png

hetzner_vswitch_setup.png

## Secure hosts

* [ ] Create last-resort root password
* [ ] Setup non-root sudo account (ansiblize this?)