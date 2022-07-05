---
description: Using MetalLB with pfsense and BGP
---
# MetalLB with pfSense

This is an addendum to the MetalLB recipe, explaining how to configure MetalLB to perform BGP peering with a pfSense firewall.

!!! summary "Ingredients"

    * [X] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [X] [MetalLB](/kubernetes/loadbalancer/metallb/) deployed
    * [X] One or more pfSense firewalls
    * [X] Basic familiarity with pfSense operation

## Preparation

Complete the [MetalLB](/kubernetes/loadbalancer/metallb/) installation, including the process of identifying ASNs for both your pfSense firewall and your MetalLB configuration.

Install the FRR package in pfsense, under **System -> Package Manager -> Available Packages**

### Configure FRR Global/Zebra

Under **Services -> FRR Global/Zebra**, enable FRR, set your router ID (*this will be your router's peer IP in MetalLB config*), and set a master password (*because apparently you have to, even though we don't use it*):

![Enabling BGP routing](/images/metallb-pfsense-00.png)

### Configure FRR BGP

Under **Services -> FRR BGP**, globally enable BGP, and set your local AS and router ID:

![Enabling BGP routing](/images/metallb-pfsense-01.png)

### Configure FRR BGP Advanced

Use the tabs at the top of the FRR configuration to navigate to "**Advanced**"...

![Enabling BGP routing](/images/metallb-pfsense-02.png)

... and scroll down to **eBGP**. Check the checkbox titled "**Disable eBGP Require Policy**:

![Enabling BGP routing](/images/metallb-pfsense-03.png)

!!! question "Isn't disabling a policy check a Bad Idea(tm)?"
    If you're an ISP, sure. If you're only using eBGP to share routes between MetalLB and pfsense, then applying policy is an unnecessary complication.[^1]

### Configure BGP neighbors

#### Peer Group

It's useful to bundle our configurations within a "peer group" (*a collection of settings which applies to all neighbors who are members of that group*), so start off by creating a neighbor with the name of "**metallb**" (*this will become a peer-group*). Set the remote AS (*because you have to*), and leave the rest of the settings as default.

!!! question "Why bother with a peer group?"
    > If we're not changing any settings, why are we bothering with a peer group?

    We may later want to change settings which affect all the peers, such as prefix lists, route-maps, etc. We're doing this now for the benefit of our future selves 💪

#### Individual Neighbors

Now add each node running MetalLB, as a BGP neighbor. Pick the peer-group you created above, and configure each neighbor's ASN:

![Enabling BGP routing](/images/metallb-pfsense-04.png)

## Serving

Once you've added your neighbors, you should be able to use the FRR tab navigation (*it's weird, I know!*) to get to Status / BGP, and identify your neighbors, and all the routes learned from them. In the screenshot below, you'll note that **most** routes are learned from all the neighbors - that'll be service backed by a daemonset, running on all nodes. The `192.168.32.3/32` route, however, is only received from `192.168.33.22`, meaning only one node is running the pods backing this service, so only those pods are advertising the route to pfSense:

![BGP route-](/images/metallb-pfsense-05.png)

### Troubleshooting

If you're not receiving any routes from MetalLB, or if the neighbors aren't in an established state, here are a few suggestions for troubleshooting:

1. Confirm on PFSense that the BGP connections (*TCP port 179*) are not being blocked by the firewall
2. Examine the metallb speaker logs in the cluster, by running `kubectl logs -n metallb-system -l app.kubernetes.io/name=metallb`
3. SSH to the pfsense, start a shell and launch the FFR shell by running `vtysh`. Now you're in a cisco-like console where commands like `show ip bgp sum` and `show ip bgp neighbors <neighbor ip> received-routes` will show you interesting debugging things.

--8<-- "recipe-footer.md"

[^1]: If you decide to deploy some policy with route-maps, prefix-lists, etc, it's all found under **Services -> FRR Global/Zebra** 🦓
