---
date: 2023-02-22
categories:
  - note
tags:
  - proxmox
title: Proxmox 7.3 enforces 1500 MTU, breaks previously-working jumbo-framed VMs
description: Since upgrading to Proxmox 7.3, I discovered that my vault cluster was failing to sync. Turns out, a new setting enforcing a default MTU per-VM was the culprit!
---

# That time when a Proxmox upgrade silently capped my MTU

I feed and water several Proxmox clusters, one of which was recently upgraded to PVE 7.3. This cluster runs VMs used to build a CI instance of a bare-metal Kubernetes cluster I support. Every day the CI cluster is automatically destroyed and rebuilt, to give assurance that our recent changes haven't introduced a failure which would prevent a re-install.

Since the PVE 7.3 upgrade, the CI cluster has been failing to build, because the out-of-cluster Vault instance we use to secure etcd secrets, failed to sync. After much debugging, I'd like to present a variation of a [famous haiku](https://www.cyberciti.biz/humour/a-haiku-about-dns/)[^1] to summarize the problem:

> It's not MTU! <br>
> There's no way it's MTU! <br>
> It was MTU.

Here's how it went down...

<!-- more -->

## Vault fails to sync

We're using Hashicorp vault in HA mode with [integrated (raft) storage](https://developer.hashicorp.com/vault/docs/concepts/integrated-storage), and [AWSKMS auto-unsealing](https://developer.hashicorp.com/vault/docs/configuration/seal/awskms). All you have to do is initialize vault on your first node, and then include something like this in other nodes:

```text
storage "raft" {
  path = "/var/lib/vault"
  node_id = "grumpy"

  retry_join {
    leader_api_addr = "https://192.168.37.11:8200"
    leader_ca_cert_file = "/etc/kubernetes/pki/vault/ca.pem"
  }
  retry_join {
    leader_api_addr = "https://192.168.37.12:8200"
    leader_ca_cert_file = "/etc/kubernetes/pki/vault/ca.pem"
  }
  retry_join {
    leader_api_addr = "https://192.168.37.13:8200"
    leader_ca_cert_file = "/etc/kubernetes/pki/vault/ca.pem"
  }
}
```

When vault starts up, it'll look for the leaders in the `retry_join` config, attempt to connect to them, and use raft magic to unseal themselves and join the raft.

On our victim cluster, instead of happily joining the raft, the other nodes were logging messages like this:

```bash
Feb 22 00:38:04 plum vault[32791]: 2023-02-22T00:38:04.126Z [INFO]  core: stored unseal keys supported, attempting fetch
Feb 22 00:38:04 plum vault[32791]: 2023-02-22T00:38:04.126Z [WARN]  failed to unseal core: error="stored unseal keys are supported, but none were found"
Feb 22 00:38:04 plum vault[32791]: 2023-02-22T00:38:04.648Z [ERROR] core: failed to retry join raft cluster: retry=2s err="failed to send answer to raft leader node: context deadline exceeded"
Feb 22 00:38:06 plum vault[32791]: 2023-02-22T00:38:06.648Z [INFO]  core: security barrier not initialized
Feb 22 00:38:06 plum vault[32791]: 2023-02-22T00:38:06.655Z [INFO]  core: attempting to join possible raft leader node: leader_addr=https://192.168.20.11:8200
Feb 22 00:38:06 plum vault[32791]: 2023-02-22T00:38:06.655Z [INFO]  core: attempting to join possible raft leader node: leader_addr=https://192.168.20.13:8200
Feb 22 00:38:06 plum vault[32791]: 2023-02-22T00:38:06.655Z [INFO]  core: attempting to join possible raft leader node: leader_addr=https://192.168.20.12:8200
Feb 22 00:38:06 plum vault[32791]: 2023-02-22T00:38:06.657Z [ERROR] core: failed to get raft challenge: leader_addr=https://192.168.20.13:8200
Feb 22 00:38:06 plum vault[32791]:   error=
Feb 22 00:38:06 plum vault[32791]:   | error during raft bootstrap init call: Error making API request.
Feb 22 00:38:06 plum vault[32791]:   |
Feb 22 00:38:06 plum vault[32791]:   | URL: PUT https://192.168.20.13:8200/v1/sys/storage/raft/bootstrap/challenge
Feb 22 00:38:06 plum vault[32791]:   | Code: 503. Errors:
Feb 22 00:38:06 plum vault[32791]:   |
Feb 22 00:38:06 plum vault[32791]:   | * Vault is sealed
Feb 22 00:38:06 plum vault[32791]:
```

!!! note
    In hindsight, the `context deadline exceeded` was a clue, but it was hidden in the noise of multiple nodes failing to join each other.

I discovered that an identical CI cluster on a non-upgrading proxmox didn't exhibit the error.

After exhausting all the conventional possibilites (*vault cli version mismatch, SSL issues, DNS*), I decided to check whether MTU was still working (*this cluster had worked fine until recently*).

Using `ping -M do 4000 <target>`, I was surprised to discover that my CI VMs could **not** ping each other with unfragmented, large payloads. I checked the working cluster - in that environment, I **could** pass large ping payloads.

## It's MTU, right?

> "Ha! The VMs MTUs must be set wrong!" - me

Nope. Checked that:

```yaml
network:
    version: 2
    ethernets:
        ens18:
            dhcp4: no
            optional: true
            mtu: 8894
        ens19:
            dhcp4: no
            optional: true
            mtu: 8894
    bonds:
        cluster:
            mtu: 8894
    <snip the irrelevant stuff>
```

## Proxmox upgrade broke MTU?

> "OK, so maybe the proxmox upgrade has removed the MTU we set on the bridge." - also me

Nope. Still good:

```bash
root@proxmox:~# cat /etc/network/interfaces
auto lo
iface lo inet loopback

iface eno1np0 inet manual

auto vmbr0
iface vmbr0 inet static
	address 10.0.1.215
	netmask 255.255.255.0
	gateway 10.0.1.1
	bridge_ports eno1np0
	bridge_stp off
	bridge_fd 0
	mtu 9000

iface eno2np1 inet manual
root@proxmox:~#
```

> "Huh." - me, final state

OK, so every NIC on this proxmox host **should** be at MTU 9000, right?

Well, not exactly...

```bash
root@proxmox:~# ip link list | grep mtu
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
2: eno1np0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq master vmbr0 state UP mode DEFAULT group default qlen 1000
3: eno2np1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
4: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc noqueue state UP mode DEFAULT group default qlen 1000
<snip>
13: tap100i1: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master vmbr0v180 state UNKNOWN mode DEFAULT group default qlen 1000
14: tap100i2: <BROADCAST,MULTICAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master vmbr0v42 state UNKNOWN mode DEFAULT group default qlen 1000
```

## MTU is broken on Proxmox :(

Aha, what is going on here? Every interface seems to have been set to an MTU of 1500.

In PVE 7.3, we now have the option to set the MTU of each network interface. This defaults to `1500`, but by setting to the magic number of `1`, the interface MTU will align with the MTU of its bridge.

So we should be able to just set each interface's MTU to `9000`, right?

Well no. Not if we're using VLANs (*which, of course we are, in a multi-networked replica of a real cluster, complete with multi-homed virtual firewalls!*)

It seems that the addition of MTU settings to Proxmox virtio NICs via the UI has broken the way that MTU is set on the tap interfaces on the proxmox hypervisor.

If you use a VLAN tag, your MTU is fixed at `1500`, regardless of what you set. If you **don't** use a VLAN tag, your MTU is set to the MTU of your bridge (*the old behaviour*), regardless of what you set.

So I created a [bug report](https://bugzilla.proxmox.com/show_bug.cgi?id=4547).

## Workaround for Proxmox MTU issue

I was hoping to be able to post a workaround here, a method to allow us to continue to use jumbo frames in our VLAN-aware CI cluster environment. Unfortunately, I've not been able to find a way to make this work, so until the bug is fixed, I've had to revert my CI clusters to a `1500` MTU, which now represents a minor deviation from our production clusters :(

## Summary

MTU issues cause mysterious failures in mysterious ways. Always test your MTU using `ping -M do -s <a big number> <target>`, to ensure that you actually **can** pass larger-than-normal packets!

[^1]: If it's not DNS, it's probably MTU.

--8<-- "blog-footer.md"
