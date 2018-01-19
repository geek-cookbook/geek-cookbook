# NVidia GPU

## Ingredients

1. [Nvidia drivers](http://www.nvidia.com/Download/driverResults.aspx/104284/en-us) for your GPU
2. Some form of X11 GUI preconfigured on your linux host (yes, it's a PITA, but it's necessary for overclocking)

## Preparation

### Install kernel-devel and gcc

The nVidia drivers will need the kernel development packages for your OS installed, as well as gcc. Run the following (for CentOS - there will be an Ubuntu equivalent):

```yum install kernel-devel-$(uname -r) gcc```

### Remove nouveau

Your host probably already includes nouveau, free/libre drivers for Nvidia graphics card. These won't cut it for mining, so blacklist them to avoid conflict with the dirty, proprietary Nvidia drivers:

```
echo 'blacklist nouveau' >> /etc/modprobe.d/blacklist.conf
dracut /boot/initramfs-$(uname -r).img $(uname -r) --force
systemctl disable gdm
reboot
```

### Install Nvidia drivers

Download and uncompress the [Nvidia drivers](http://www.nvidia.com/Download/driverResults.aspx/104284/en-us), and execute the installation as root, with a command something like this:

```bash NVIDIA-Linux-x86_64-352.30.run```

Update your X11 config by running:

```
nvidia-xconfig
```

### Enable GUID

```
systemctl enable gdm
ln -s '/usr/lib/systemd/system/gdm.service' '/etc/systemd/system/display-manager.service'
reboot
```

## Overclock

!!! warning
    Like overclocking itself, this process is still a work in progress. YMMV.

Of course, you want to squeeze the optimal performance out of your GPU. This is where the X11 environment is required - to adjust GPU clock/memory settings, you need to use the ```nvidia-settings``` command, which (_stupidly_) requires an X11 display, even if you're just using the command line.

This command gives you a "fake" screen so that X11 will run, even on a headless machine managed by SSH only:

```
nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0"
```
