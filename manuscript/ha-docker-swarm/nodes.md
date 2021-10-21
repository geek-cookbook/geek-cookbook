# Nodes

Let's start building our cluster. You can use either bare-metal machines or virtual machines - the configuration would be the same. To avoid confusion, I'll be referring to these as "nodes" from now on.

!!! note
    In 2017, I **initially** chose the "[Atomic](https://www.projectatomic.io/)" CentOS/Fedora image for the swarm hosts, but later found its outdated version of Docker to be problematic with advanced features like GPU transcoding (in [Plex](/recipes/plex/)), [Swarmprom](/recipes/swarmprom/), etc. In the end, I went mainstream and simply preferred a modern Ubuntu installation.

## Ingredients

!!! summary "Ingredients"
    New in this recipe:

    * [ ] 3 x nodes (*bare-metal or VMs*), each with:
          * A mainstream Linux OS (*tested on either [CentOS](https://www.centos.org) 7+ or [Ubuntu](http://releases.ubuntu.com) 16.04+*)
          * At least 2GB RAM
          * At least 20GB disk space (_but it'll be tight_)
    * [ ] Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)

## Preparation

### Permit connectivity

Most modern Linux distributions include firewall rules which only only permit minimal required incoming connections (like SSH). We'll want to allow all traffic between our nodes. The steps to achieve this in CentOS/Ubuntu are a little different...

#### CentOS

Add something like this to `/etc/sysconfig/iptables`:

```bash
# Allow all inter-node communication
-A INPUT -s 192.168.31.0/24 -j ACCEPT
```

And restart iptables with ```systemctl restart iptables```

#### Ubuntu

Install the (*non-default*) persistent iptables tools, by running `apt-get install iptables-persistent`, establishing some default rules (*dkpg will prompt you to save current ruleset*), and then add something like this to `/etc/iptables/rules.v4`:

```bash
# Allow all inter-node communication
-A INPUT -s 192.168.31.0/24 -j ACCEPT
```

And refresh your running iptables rules with `iptables-restore < /etc/iptables/rules.v4`

### Enable hostname resolution

Depending on your hosting environment, you may have DNS automatically setup for your VMs. If not, it's useful to set up static entries in /etc/hosts for the nodes. For example, I setup the following:

- 192.168.31.11   ds1     ds1.funkypenguin.co.nz
- 192.168.31.12   ds2     ds2.funkypenguin.co.nz
- 192.168.31.13   ds3     ds3.funkypenguin.co.nz

### Set timezone

Set your local timezone, by running:

```bash
ln -sf /usr/share/zoneinfo/<your timezone> /etc/localtime
```

## Serving

After completing the above, you should have:

!!! summary "Summary"
    Deployed in this recipe:

    * [X] 3 x nodes (*bare-metal or VMs*), each with:
          * A mainstream Linux OS (*tested on either [CentOS](https://www.centos.org) 7+ or [Ubuntu](http://releases.ubuntu.com) 16.04+*)
          * At least 2GB RAM
          * At least 20GB disk space (_but it'll be tight_)
    * [X] Connectivity to each other within the same subnet, and on a low-latency link (_i.e., no WAN links_)

--8<-- "recipe-footer.md"
