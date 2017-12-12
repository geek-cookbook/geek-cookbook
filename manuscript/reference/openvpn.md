# OpenVPN

Sometimes you need an OpenVPN tunnel between your docker hosts and some other environment. I needed this to provide connectivity between swarm-deployed services like Home Assistant, and my IOT devices within my home LAN.

OpenVPN is one application which doesn't really work in a swarm-type deployment, since each host will typically require a unique certificate/key to connect to the VPN anyway.

In my case, I needed each docker node to connect via [OpenVPN](http://www.openvpn.org) back to a [pfsense](http://www.pfsense.org) instance, but there were a few gotchas related to OpenVPN at CentOS Atomic which I needed to address first.

## SELinux for OpenVPN

Yes, SELinux. Install a custom policy permitting a docker container to create tun interfaces, like this:

````
cat << EOF > docker-openvpn.te
module docker-openvpn 1.0;

require {
	type svirt_lxc_net_t;
	class tun_socket create;
}

#============= svirt_lxc_net_t ==============
allow svirt_lxc_net_t self:tun_socket create;

EOF

checkmodule -M -m -o docker-openvpn.mod docker-openvpn.te
semodule_package -o docker-openvpn.pp -m docker-openvpn.mod
semodule -i docker-openvpn.pp
````

## Insert the tun module

Even with the SELinux policy above, I still need to insert the "tun" module into the running kernel at the host-level, before a docker container can use it to create a tun interface.

Run the following to auto-insert the tun module on boot:

````
cat << EOF >> /etc/rc.d/rc.local
# Insert the "tun" module so that the vpn-client container can access /dev/net/tun
/sbin/modprobe tun
EOF
chmod 755 /etc/rc.d/rc.local
````

## Connect the VPN

Finally, for each node, I exported client credentials, and SCP'd them over to the docker node, into /root/my-vpn-configs-here/. I also had to use the NET_ADMIN cap-add parameter, as illustrated below:

````
docker run -d --name vpn-client \
  --restart=always --cap-add=NET_ADMIN --net=host \
  --device /dev/net/tun \
  -v /root/my-vpn-configs-here:/vpn:z \
  ekristen/openvpn-client --config /vpn/my-host-config.ovpn
````

Now every time my node boots, it establishes a VPN tunnel back to my pfsense host and (_by using custom configuration directives in OpenVPN_) is assigned a static VPN IP.


## Your comments?
