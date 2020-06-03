# Keepalived

While having a self-healing, scalable docker swarm is great for availability and scalability, none of that is any good if nobody can connect to your cluster.

In order to provide seamless external access to clustered resources, regardless of which node they're on and tolerant of node failure, you need to present a single IP to the world for external access.

Normally this is done using a HA loadbalancer, but since Docker Swarm aready provides the load-balancing capabilities (*[routing mesh](https://docs.docker.com/engine/swarm/ingress/)*), all we need for seamless HA is a virtual IP which will be provided by more than one docker node.

This is accomplished with the use of keepalived on at least two nodes.

## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] At least 2 x swarm nodes
    * [X] low-latency link (i.e., no WAN links)

    New:

    * [ ] At least 3 x IPv4 addresses (one for each node and one for the virtual IP)

## Preparation

### Enable IPVS module

On all nodes which will participate in keepalived, we need the "ip_vs" kernel module, in order to permit serivces to bind to non-local interface addresses.

Set this up once for both the primary and secondary nodes, by running:

```
echo "modprobe ip_vs" >> /etc/rc.local
modprobe ip_vs
```

### Setup nodes

Assuming your IPs are as follows:

* 192.168.4.1 : Primary
* 192.168.4.2 : Secondary
* 192.168.4.3 : Virtual

Run the following on the primary
```
docker run -d --name keepalived --restart=always \
  --cap-add=NET_ADMIN --net=host \
  -e KEEPALIVED_UNICAST_PEERS="#PYTHON2BASH:['192.168.4.1', '192.168.4.2']" \
  -e KEEPALIVED_VIRTUAL_IPS=192.168.4.3 \
  -e KEEPALIVED_PRIORITY=200 \
  osixia/keepalived:1.3.5
```

And on the secondary:
```
docker run -d --name keepalived --restart=always \
  --cap-add=NET_ADMIN --net=host \
  -e KEEPALIVED_UNICAST_PEERS="#PYTHON2BASH:['192.168.4.1', '192.168.4.2']" \
  -e KEEPALIVED_VIRTUAL_IPS=192.168.4.3 \
  -e KEEPALIVED_PRIORITY=100 \
  osixia/keepalived:1.3.5
```

## Serving

That's it. Each node will talk to the other via unicast (no need to un-firewall multicast addresses), and the node with the highest priority gets to be the master. When ingress traffic arrives on the master node via the VIP, docker's routing mesh will deliver it to the appropriate docker node.

## Chef's notes 

1. Some hosting platforms (*OpenStack, for one*) won't allow you to simply "claim" a virtual IP. Each node is only able to receive traffic targetted to its unique IP, unless certain security controls are disabled by the cloud administrator. In this case, keepalived is not the right solution, and a platform-specific load-balancing solution should be used. In OpenStack, this is Neutron's "Load Balancer As A Service" (LBAAS) component. AWS, GCP and Azure would likely include similar protections.
2. More than 2 nodes can participate in keepalived. Simply ensure that each node has the appropriate priority set, and the node with the highest priority will become the master.