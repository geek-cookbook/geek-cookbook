# NVidia GPU

!!! warning
    This is not a complete recipe - it's a component of the [cryptominer](/recipies/cryptominer/) "_uber-recipe_", but has been split into its own page to reduce complexity.

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

### Preparation

!!! warning
    Like overclocking itself, this process is still a work in progress. YMMV.

Of course, you want to squeeze the optimal performance out of your GPU. This is where the X11 environment is required - to adjust GPU clock/memory settings, you need to use the ```nvidia-settings``` command, which (_stupidly_) **requires** an X11 display, even if you're just using the command line.

The following command: configures X11 for a "fake" screen so that X11 will run, even on a headless machine managed by SSH only, and ensures that the PCI bus ID of every NVidia device is added to the xorg.conf file (to avoid errors about "_(EE) no screens found(EE)_")

```
nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=28 --use-display-device="DFP-0" --connected-monitor="DFP-0" --enable-all-gpus --separate-x-screens
```

!!! note
    The script below was taken from  https://github.com/Cyclenerd/ethereum_nvidia_miner

Make a directory for your overclocking script. Mine happens to be /root/overclock/, but use whatever you like.

Create settings.conf as follows:

```
# Known to work with Nvidia 1080ti, but probably not optimal. It's an eternal work-in-progress.
MY_WATT="200"
MY_CLOCK="100"
MY_MEM="400"
MY_FAN="60"
```

Then create nvidia-overclock.sh as follows:

```
#!/usr/bin/env bash

#
# nvidia-overclock.sh
# Author: Nils Knieling - https://github.com/Cyclenerd/ethereum_nvidia_miner
#
# Overclocking with nvidia-settings
#

# Load global settings settings.conf
if ! source ~/overclock/settings.conf; then
	echo "FAILURE: Can not load global settings 'settings.conf'"
	exit 9
fi

export DISPLAY=:0

# Graphics card 1 to 6
for MY_DEVICE in {0..5}
do
	# Check if card exists
	if nvidia-smi -i $MY_DEVICE >> /dev/null 2>&1; then
		nvidia-settings -a "[gpu:$MY_DEVICE]/GPUPowerMizerMode=1"
		# Fan speed
		nvidia-settings -a "[gpu:$MY_DEVICE]/GPUFanControlState=1"
		nvidia-settings -a "[fan:$MY_DEVICE]/GPUTargetFanSpeed=$MY_FAN"
		# Graphics clock
		nvidia-settings -a "[gpu:$MY_DEVICE]/GPUGraphicsClockOffset[3]=$MY_CLOCK"
		# Memory clock
		nvidia-settings -a "[gpu:$MY_DEVICE]/GPUMemoryTransferRateOffset[3]=$MY_MEM"
                # Set watt/powerlimit. This is also set in miner.sh at autostart.
                sudo nvidia-smi -i "$MY_DEVICE" -pl "$MY_WATT"
	fi
done

echo
echo "Done"
echo
```

### Start your engine!

**Once** you've got X11 running correctly, execute ,/nvidia-overclock.sh, and you should see something like the following:

```
[root@kvm overclock]# ./nvidia-overclock.sh
  Attribute 'GPUPowerMizerMode' (kvm.funkypenguin.co.nz:0[gpu:0]) assigned value 1.
  Attribute 'GPUFanControlState' (kvm.funkypenguin.co.nz:0[gpu:0]) assigned value 1.
  Attribute 'GPUTargetFanSpeed' (kvm.funkypenguin.co.nz:0[fan:0]) assigned value 60.
  Attribute 'GPUGraphicsClockOffset' (kvm.funkypenguin.co.nz:0[gpu:0]) assigned value 100.
  Attribute 'GPUMemoryTransferRateOffset' (kvm.funkypenguin.co.nz:0[gpu:0]) assigned value 400.

Power limit for GPU 00000000:04:00.0 was set to 150.00 W from 150.00 W.
All done.

Done

[root@kvm overclock]#
```

Play with changing your settings.conf file until you break it, and then go back one revision :)

## Continue your adventure

Now, continue to the next stage of your grand mining adventure:

1. Build your [mining rig](/recipies/cryptominer/mining-rig/) 💻
2. Setup your [AMD](/recipies/cryptominer/amd-gpu/) or Nvidia (_this page_) GPUs 🎨
3. Sign up for [mining pools](/recipies/cryptominer/mining-pool/) :swimmer:
4. Setup your miners with [Miner Hotel](/recipies/cryptominer/minerhotel/) 🏨
5. Send your coins to [exchanges](/recipies/cryptominer/exchange/) or [wallets](/recipies/cryptominer/wallet/) 💹
6. [Monitor](/recipies/cryptominer/monitor/) your empire :heartbeat:
7. [Profit](/recipies/cryptominer/profit/)! 💰


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
