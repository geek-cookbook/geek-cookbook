!!! warning
    This is not a complete recipe - it's a component of the [cryptominer](/recipies/cryptominer/) "_uber-recipe_", but has been split into its own page to reduce complexity.

# AMD GPU

## Ingredients

1. [AMD drivers](http://support.amd.com/en-us/kb-articles/Pages/Radeon-Software-for-Linux-Release-Notes.aspx) for your GPU
2. [Linux version](https://bitcointalk.org/index.php?topic=1809527.0) of "atiflash" command
3. A [VBIOS rom](https://anorak.tech/c/downloads) compatible with your GPU model and memory manufacturer

## Preparation

### Install the drivers

There are links on the AMD driver download page (_linked above_) to drivers for RHEL/CentOS6, RHEL/CentOS7, and Ubuntu 16.04. As I write this, the latest version is **amdgpu-pro-17.50-511655**.

!!! note
    You'll find reference online to the "blockchain" drivers. These were an earlier, [beta release](http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-Pro-Beta-Mining-Driver-for-Linux-Release-Notes.aspx) which have been superseded by version 17.50 and later. You can ignore these.

Uncompress the drivers package, and run the following:

```./amdgpu-install --opencl=legacy --headless```

If you have a newer (_than my 5-year-old one!_) motherboard/CPU, you can also try the following, for ROCm support (_which might allow you some more software-based overclocking powers_):

```./amdgpu-install --opencl=legacy,rocm --headless```

Reboot upon completion.

### Flash the BIOS

Yes, this sounds scary, but it's not as bad as it sounds, if you want better performance from your GPUs, you **have** to flash your GPU BIOS.

#### Why flash BIOS?

Here's my noob-level version of why:

1.  GPU-mining performance is all about the **memory speed** of your GPU - you get the best mining from the fastest internal timings. So you want to optimize your GPU to do really fast memory work, which is not how it's designed by default.

2. The **processor** on your GPU sits almost idle, so you **lower** the power to the processor (_undervolt_) to save some power.

3. As it turns out, the factory memory timings of the RX5xx series were particularly poor.

As an aside, here's an illustration re why you'd **want** to flash your BIOS. Below is the mining throughput of 2 AMD RX580s I purchased together. Guess which one had its BIOS flashed?

```
ETH: GPU0 30.115 Mh/s, GPU1 22.176 Mh/s
```

Here's the power consumption of the two GPUs while doing the above test:

GPU1 (original ROM)
```
GFX Clocks and Power:
        1750 MHz (MCLK)
        1411 MHz (SCLK)
        144.107 W (VDDC)
        16.0 W (VDDCI)
        171.161 W (max GPU)
        172.209 W (average GPU)

GPU Temperature: 67 C
GPU Load: 100 %
```

GPU0 (flashed ROM)
```
GFX Clocks and Power:
        2050 MHz (MCLK)
        1150 MHz (SCLK)
        87.155 W (VDDC)
        16.0 W (VDDCI)
        117.152 W (max GPU)
        116.1 W (average GPU)

GPU Temperature: 62 C
GPU Load: 100 %
```

So, by flashing the BIOS, I gained 8 MH/s (a 36% increase), while reducing power consumption by ~40W!

#### How to flash AMD GPU BIOS?

1. Get [atiflash for linux](https://bitcointalk.org/index.php?topic=1809527.0).

2. Identify which card you want to flash, by running ```./atiflash -i```

Example output below:

```
[root@kvm ~]# ./atiflash -i

adapter bn dn dID       asic           flash      romsize test    bios p/n
======= == == ==== =============== ============== ======= ==== ================
   0    01 00 67DF Ellesmere       M25P20/c         40000 pass 113-1E3660EU-O55
[root@kvm ~]#
```

3. Save the original, factory ROM, by running ```./atiflash -s <adapter number> <filename to save>```

Example below:
```
[root@kvm ~]# ./atiflash -s 0 rx580-4gb-299-1E366-101SA.orig.rom
0x40000 bytes saved, checksum = 0x7FBF
```

Now find an appropriate ROM to flash onto the card, and run ```atiflash -p <adatper number> <rom filename>

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes a range of RX580-compatible ROMs, some of which I've tweaked for my own GPUs. 


Example below:
```
[root@kvm ~]# ./atiflash -f -p 0 Insan1ty\ R9\ 390X\ BIOS\ v1.81/R9\ 290X/MEM\ MOD\ --\ ELPIDA/290X_ELPIDA_MOD_V1.8.rom
Old SSID: E285
New SSID: 9395
Old P/N: 113-E285FOC-U005
New P/N: 113-GRENADA_XT_C671_D5_8GB_HY_W
Old DeviceID: 67B1
New DeviceID: 67B0
Old Product Name: C67111 Hawaii PRO OC GDDR5 4GB 64Mx32 300e/150m
New Product Name: C67130 Grenada XT A0 GDDR5 8GB 128Mx32 300e/150m
Old BIOS Version: 015.044.000.011.000000
New BIOS Version: 015.049.000.000.000000
Flash type: M25P10/c
Burst size is 256
20000/20000h bytes programmed
20000/20000h bytes verified

Restart System To Complete VBIOS Update.
[root@kvm ~]#
```

Reboot the system, [hold onto your butts](https://www.youtube.com/watch?v=o0YWRXJsMyM), and wait for your newly-flashed GPU to fire up.

#### If it goes wrong

The safest way to do this is to run more than one GPU, and to flash the GPUs one-at-a-time, rebooting after each. That way, even if you make your GPU totally unresponsive, you'll still get access to your system to flash it back to the factory ROM.

That said, it's very unlikely that a flashed GPU won't let you boot at all though. In the (legion) cases where I overclocked my RX580 too far, I was able choose to boot into rescue mode in CentOS7 (bypassing the framebuffer / drm initialisation), and reflash my card back to its original BIOS.

#### Mooar tweaking! 🔧

If you want to tweak the BIOS yourself, download the [Polaris bios editor](https://github.com/jaschaknack/PolarisBiosEditor) and tweak away!

## Continue your adventure

Now, continue to the next stage of your grand mining adventure:

1. Build your [mining rig](/recipies/cryptominer/mining-rig/) 💻
2. Setup your AMD (_this page_) or [Nvidia](/recipies/cryptominer/nvidia-gpu/) GPUs 🎨
3. Sign up for [mining pools](/recipies/cryptominer/mining-pool/) :swimmer:
3. Setup your miners with [Miner Hotel](/recipies/cryptominer/minerhotel/) 🏨
4. Send your coins to [exchanges](/recipies/cryptominer/exchange/) or [wallets](/recipies/cryptominer/wallet/) 💹
5. [Monitor](/recipies/cryptominer/monitor/) your empire :heartbeat:
6. [Profit](/recipies/cryptominer/profit/)! 


## Chef's Notes

1. My two RX580 cards (_bought alongside each other_) perform slightly differently. GPU0 works with a 2050Mhz memory clock, but GPU1 only works at 2000Mhz. Anything over 2000Mhz causes system instability. YMMV.

### Tip your waiter (donate) 

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 

### Your comments? 
