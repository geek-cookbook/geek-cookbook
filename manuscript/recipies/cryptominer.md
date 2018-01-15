hero: We dig dig digga-dig dig!

# CryptoMiner

This is a diversion from my usual recipes - since a hardware-based crypto currency miner can't really use a docker swarm :)

Ultimately I hope to move all the configuration / mining executables into docker containers, but for now, they're running on a CentOS7 host for direct access to GPUs. (Apparently it _may_ be possible to pass-thru the GPUs to docker containers, but I wanted stability first, before abstracting my hardware away from my miners)

![NAME Screenshot](../images/cryptominer.png)


## Menu



## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. Access to NZB indexers and Usenet servers
4. DNS entries configured for each of the NZB tools in this recipe that you want to use

## Preparation

### Setup data locations



## Your comments?



Details

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. 3. DNS entry for the hostname you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP

## Preparation

### Setup accounts

You'll want to setup accounts at the following (if you use the URLs below, I get a small referral bonus)

* Nicehash
* [Coinbase](https://www.coinbase.com/join/5a4d1ed0ee3de40195a695c8)
* [Binance](https://www.binance.com/?ref=15312815)
* zcl.suprnova.cc for zcash mining
* bitrex (use for zcl wallet) - need to verfy account_
* [cryptopia](https://www.cryptopia.co.nz/Register?referrer=funkypenguin)
* [altpocket](https://altpocket.io/?ref=ilVqdeWbAv)
* https://www.cryptostache.com/2017/11/10/keeping-track-cryptocurrency-portfolio-best-apps-2017/

# For flashing
https://bitcointalk.org/index.php?topic=1809527.0

# Testing

--
/opt/minerhotel/bin/claymore/ethdcrminer64 -epool stratum+tcp://daggerhashimoto.usa.nicehash.com:3353 -ewal 394LeTTJFXkY6yGR95kY5q2Er68P81fDtv -epsw x -esm 3 -allpools 1 -estale 0 -dpool stratum+tcp://decred.usa.nicehash.com:3354 -dwal 394LeTTJFXkY6yGR95kY5q2Er68P81fDtv -di 012 -dcri 28 -cclock 1200 -cvddc 900 -mclock 2250 -mvddc 850 -tstop 85 -tt 65 -fanmin 10 -fanmax 60 -gser 5 -lidag 5 -asm 1
---

## Results of the flash

```
GPU #0: Ellesmere, 4078 MB available, 36 compute units
GPU #1: Ellesmere, 4082 MB available, 36 compute units
```

Speed:
```
ETH: GPU0 30.115 Mh/s, GPU1 22.176 Mh/s
```

Power consumption (stock)
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

Power consumption (flashed)

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

R290 flash. Started with 290X elpida. Not elpida. Trying hynix.

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


### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/wekan:

```
mkdir /var/data/wekan
cd /var/data/wekan
mkdir -p {wekan-db,wekan-db-dump}
```

### Prepare environment

Create wekan.env, and populate with the following variables
```
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
MONGO_URL=mongodb://wekandb:27017/wekan
ROOT_URL=https://wekan.example.com
MAIL_URL=smtp://wekan@wekan.example.com:password@mail.example.com:587/
MAIL_FROM="Wekan <wekan@wekan.example.com>"
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:

  wekandb:
    image: mongo:3.2.15
    command: mongod --smallfiles --oplogSize 128
    networks:
      - internal
    volumes:
      - /var/data/wekan/wekan-db:/data/db
      - /var/data/wekan/wekan-db-dump:/dump

  proxy:
    image: zappi/oauth2_proxy
    env_file: /var/data/wekan/wekan.env
    networks:
      - traefik
      - internal
    deploy:
      labels:
        - traefik.frontend.rule=Host:wekan.example.com
        - traefik.docker.network=traefik
        - traefik.port=4180
    command: |
      -cookie-secure=false
      -upstream=http://wekan:80
      -redirect-url=https://wekan.example.com
      -http-address=http://0.0.0.0:4180
      -email-domain=example.com
      -provider=github

  wekan:
    image: wekanteam/wekan:latest
    networks:
      - internal
    env_file: /var/data/wekan/wekan.env

networks:
  traefik:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.3.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.



## Serving

### Launch Wekan stack

Launch the Wekan stack by running ```docker stack deploy wekan -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

## Chef's Notes

1. If you wanted to expose the Wekan UI directly, you could remove the oauth2_proxy from the design, and move the traefik-related labels directly to the wekan container. You'd also need to add the traefik network to the wekan container.

## Your comments?




my part number on the RX580s is
299-1E366-101SA

Found this page:
https://anorak.tech/t/sapphire-rx-580-nitro-4g-elpida-p-n-299-1e366-101sa/3486



*Theater Pro supports commands -i, p, s, cf, cr, t, v and options -f, -noremap.
[root@kvm ~]# ./atiflash -i

adapter bn dn dID       asic           flash      romsize test    bios p/n
======= == == ==== =============== ============== ======= ==== ================
   0    01 00 67DF Ellesmere       M25P20/c         40000 pass 113-1E3660EU-O55
[root@kvm ~]#
[root@kvm ~]# ./atiflash -s 0 rx580-4gb-299-1E366-101SA.orig.rom
0x40000 bytes saved, checksum = 0x7FBF
[root@kvm ~]# du -sh rx580-4gb-299-1E366-101SA.orig.rom
256K	rx580-4gb-299-1E366-101SA.orig.rom
[root@kvm ~]#


Read this:
https://medium.com/@lukehamilton/flash-your-rx-470-card-on-mac-linux-7391fb78b6f6


777000000000000022AA1C00315A5B36A0550F15B68C1506004082007C041420CA8980A9020004C01712262B612B3715


1500 : 777000000000000022AA1C00315A6B3CA0550F15B68C1506006AE4007C041420CA8980A9020000001712262B612B3715
1625 : 777000000000000022AA1C0073627C41B0551016BA0D9606006C060104061420EA8940AA030000001914292E692E3B16
1750 : 777000000000000022AA1C00B56A7D46C0551017BE8E1607006C07010C081420FA8900AB030000001B162C3171313F17
2000 : 777000000000000022AA1C00315A5B36A0550F15B68C1506004082007C041420CA8980A9020004C01712262B612B3715


999000000000000022559D0010DE5B4480551312B74C450A00400600750414206A8900A00200312010112D34A42A3816
777000000000000022AA1C00B56A6D46C0551017BE8E060C006AE6000C081420EA8900AB030000001B162C31C0313F17




UPDATE eventum_issue
JOIN eventum_issue_user ON isu_iss_id = iss_id
JOIN eventum_user ON isu_usr_id = usr_id
SET isu_usr_id = (select usr_id from eventum_user where usr_email = 'rachael@prophecy.net.nz'), isu_assigned_date = NOW()
WHERE iss_closed_date IS NULL AND usr_email = 'colleen@prophecy.net.nz' ;




[root@kvm ~]# ./atiflash -p 0 Sapphire\ RX\ 580\ Nitro\(plus\)\ 4GB\ Hynix\ Elpida\ Mod\ ETH.rom
Old SSID: E366
New SSID: E366
Old P/N: 113-1E3660EU-O55
New P/N: 113-1E3660EU-O55
Old DeviceID: 67DF
New DeviceID: 67DF
Old Product Name: E366 Polaris20 XTX A1 GDDR5 128Mx32 4GB
New Product Name: E366 Polaris20 XTX A1 GDDR5 128Mx32 4GB
Old BIOS Version: 015.050.002.001.000000
New BIOS Version: 015.050.002.001.000000
Flash type: M25P20/c
Burst size is 256
40000/40000h bytes programmed
40000/40000h bytes verified

Restart System To Complete VBIOS Update.
[root@kvm ~]#




blacklisted fglrx too

https://www.titancomputers.com/Install-Nvidia-Drivers-on-CentOS-7-s/1017.htm









^[[I[amdgpu-pro-local]
Name=AMD amdgpu Pro local repository
baseurl=file:///var/opt/amdgpu-pro-local
enabled=1
gpgcheck=0

Loaded plugins: fastestmirror, nvidia, versionlock
amdgpu-pro-local                                                                                                                            | 2.9 kB  00:00:00
base                                                                                                                                        | 3.6 kB  00:00:00
centos-sclo-rh                                                                                                                              | 2.9 kB  00:00:00
centos-sclo-sclo                                                                                                                            | 2.9 kB  00:00:00
docker-ce-stable                                                                                                                            | 2.9 kB  00:00:00
elrepo                                                                                                                                      | 2.9 kB  00:00:00
epel/x86_64/metalink                                                                                                                        | 3.7 kB  00:00:00
epel                                                                                                                                        | 4.7 kB  00:00:00
extras                                                                                                                                      | 3.4 kB  00:00:00
libnvidia-container/signature                                                                                                               |  455 B  00:00:00
libnvidia-container/signature                                                                                                               | 2.0 kB  00:00:00 !!!
nvidia-container-runtime/signature                                                                                                          |  455 B  00:00:00
nvidia-container-runtime/signature                                                                                                          | 2.0 kB  00:00:00 !!!
nvidia-docker/signature                                                                                                                     |  455 B  00:00:00
nvidia-docker/signature                                                                                                                     | 2.0 kB  00:00:00 !!!
updates                                                                                                                                     | 3.4 kB  00:00:00
(1/15): amdgpu-pro-local/primary_db                                                                                                         |  37 kB  00:00:00
(2/15): base/7/x86_64/group_gz                                                                                                              | 156 kB  00:00:00
(3/15): docker-ce-stable/x86_64/primary_db                                                                                                  |  11 kB  00:00:00
(4/15): elrepo/primary_db                                                                                                                   | 460 kB  00:00:00
(5/15): epel/x86_64/group_gz                                                                                                                | 266 kB  00:00:00
(6/15): epel/x86_64/primary_db                                                                                                              | 6.2 MB  00:00:03
(7/15): extras/7/x86_64/primary_db                                                                                                          | 145 kB  00:00:00
(8/15): epel/x86_64/updateinfo                                                                                                              | 868 kB  00:00:05
(9/15): libnvidia-container/primary                                                                                                         | 2.3 kB  00:00:01
(10/15): nvidia-docker/primary                                                                                                              | 3.1 kB  00:00:00
(11/15): nvidia-container-runtime/primary                                                                                                   | 2.9 kB  00:00:01
(12/15): centos-sclo-sclo/x86_64/primary_db                                                                                                 | 192 kB  00:00:10
(13/15): updates/7/x86_64/primary_db                                                                                                        | 5.2 MB  00:00:05
(14/15): base/7/x86_64/primary_db                                                                                                           | 5.7 MB  00:00:12
(15/15): centos-sclo-rh/x86_64/primary_db                                                                                                   | 2.9 MB  00:01:20
Loading mirror speeds from cached hostfile
 * base: ucmirror.canterbury.ac.nz
 * elrepo: mirror.ventraip.net.au
 * epel: ucmirror.canterbury.ac.nz
 * extras: ucmirror.canterbury.ac.nz
 * updates: ucmirror.canterbury.ac.nz
libnvidia-container                                                                                                                                          10/10
nvidia-container-runtime                                                                                                                                     18/18
nvidia-docker                                                                                                                                                20/20
Resolving Dependencies
There are unfinished transactions remaining. You might consider running yum-complete-transaction, or "yum-complete-transaction --cleanup-only" and "yum history redo last", first to finish them. If those don't work you'll have to try removing/installing packages by hand (maybe package-cleanup can help).
--> Running transaction check
---> Package opencl-amdgpu-pro.x86_64 0:17.50-511655.el7 will be installed
--> Processing Dependency: ids-amdgpu = 1.0.0-511655.el7 for package: opencl-amdgpu-pro-17.50-511655.el7.x86_64
--> Processing Dependency: amdgpu-dkms = 17.50-511655.el7 for package: opencl-amdgpu-pro-17.50-511655.el7.x86_64
--> Processing Dependency: amdgpu-core = 17.50-511655.el7 for package: opencl-amdgpu-pro-17.50-511655.el7.x86_64
--> Processing Dependency: libdrm-amdgpu = 1:2.4.82-511655.el7 for package: opencl-amdgpu-pro-17.50-511655.el7.x86_64
--> Processing Dependency: clinfo-amdgpu-pro = 17.50-511655.el7 for package: opencl-amdgpu-pro-17.50-511655.el7.x86_64
--> Processing Dependency: amdgpu-pro-core = 17.50-511655.el7 for package: opencl-amdgpu-pro-17.50-511655.el7.x86_64
--> Running transaction check
---> Package amdgpu-core.noarch 0:17.50-511655.el7 will be installed
---> Package amdgpu-dkms.noarch 0:17.50-511655.el7 will be installed
---> Package amdgpu-pro-core.noarch 0:17.50-511655.el7 will be installed
---> Package clinfo-amdgpu-pro.x86_64 0:17.50-511655.el7 will be installed
--> Processing Dependency: libopencl-amdgpu-pro-icd = 17.50-511655.el7 for package: clinfo-amdgpu-pro-17.50-511655.el7.x86_64
---> Package ids-amdgpu.noarch 0:1.0.0-511655.el7 will be installed
---> Package libdrm-amdgpu.x86_64 1:2.4.82-511655.el7 will be installed
--> Running transaction check
---> Package libopencl-amdgpu-pro-icd.x86_64 0:17.50-511655.el7 will be installed
--> Processing Dependency: libopencl-amdgpu-pro = 17.50-511655.el7 for package: libopencl-amdgpu-pro-icd-17.50-511655.el7.x86_64
--> Running transaction check
---> Package libopencl-amdgpu-pro.x86_64 0:17.50-511655.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================================================================
 Package                                       Arch                        Version                                     Repository                             Size
===================================================================================================================================================================
Installing:
 opencl-amdgpu-pro                             x86_64                      17.50-511655.el7                            amdgpu-pro-local                      2.2 k
Installing for dependencies:
 amdgpu-core                                   noarch                      17.50-511655.el7                            amdgpu-pro-local                      2.2 k
 amdgpu-dkms                                   noarch                      17.50-511655.el7                            amdgpu-pro-local                      7.1 M
 amdgpu-pro-core                               noarch                      17.50-511655.el7                            amdgpu-pro-local                      2.2 k
 clinfo-amdgpu-pro                             x86_64                      17.50-511655.el7                            amdgpu-pro-local                      198 k
 ids-amdgpu                                    noarch                      1.0.0-511655.el7                            amdgpu-pro-local                      3.7 k
 libdrm-amdgpu                                 x86_64                      1:2.4.82-511655.el7                         amdgpu-pro-local                       68 k
 libopencl-amdgpu-pro                          x86_64                      17.50-511655.el7                            amdgpu-pro-local                       11 k
 libopencl-amdgpu-pro-icd                      x86_64                      17.50-511655.el7                            amdgpu-pro-local                       29 M

Transaction Summary
===================================================================================================================================================================
Install  1 Package (+8 Dependent packages)

Total download size: 36 M
Installed size: 36 M
Is this ok [y/d/N]: ^[[Iy
Is this ok [y/d/N]: y
Downloading packages:
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                              135 MB/s |  36 MB  00:00:00
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : amdgpu-core-17.50-511655.el7.noarch                                                                                                             1/9
  Installing : ids-amdgpu-1.0.0-511655.el7.noarch                                                                                                              2/9
  Installing : amdgpu-pro-core-17.50-511655.el7.noarch                                                                                                         3/9
  Installing : libopencl-amdgpu-pro-17.50-511655.el7.x86_64                                                                                                    4/9
  Installing : libopencl-amdgpu-pro-icd-17.50-511655.el7.x86_64                                                                                                5/9
  Installing : clinfo-amdgpu-pro-17.50-511655.el7.x86_64                                                                                                       6/9
  Installing : 1:libdrm-amdgpu-2.4.82-511655.el7.x86_64                                                                                                        7/9
  Installing : amdgpu-dkms-17.50-511655.el7.noarch [####################################################                                                     ] 8/9^  Installing : amdgpu-dkms-17.50-511655.el7.noarch                                                                                                             8/9
^[[I^[[O^[[I^[[O^[[I^[[O^[[I^[[OLoading new amdgpu-17.50-511655.el7 DKMS files...
Building for 3.10.0-693.11.6.el7.x86_64
Building initial module for 3.10.0-693.11.6.el7.x86_64
Done.
Forcing installation of amdgpu

amdgpu:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.10.0-693.11.6.el7.x86_64/extra/

amdttm.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.10.0-693.11.6.el7.x86_64/extra/

amdkcl.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.10.0-693.11.6.el7.x86_64/extra/

amdkfd.ko:
Running module version sanity check.
 - Original module
   - No original module exists within this kernel
 - Installation
   - Installing to /lib/modules/3.10.0-693.11.6.el7.x86_64/extra/
Adding any weak-modules
Possible missing firmware "amdgpu/polaris12_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_smc_sk.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_smc_sk.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_gpu_info.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_gpu_info.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/si58_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/tahiti_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hainan_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hainan_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hainan_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hainan_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/tahiti_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/tahiti_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/tahiti_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/tahiti_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/banks_k_2_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hainan_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hainan_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/oland_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/verde_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/pitcairn_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/tahiti_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_mc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_asd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_sos.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_asd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mec2_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mec_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_me_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_pfp_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_ce_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mec2_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mec_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_me_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_pfp_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_ce_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mec2_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mec_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_me_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_pfp_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_ce_2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_rlc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_mec2.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_mec.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_me.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_pfp.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_ce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_sdma1.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_sdma.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_uvd.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/stoney_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/carrizo_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/mullins_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/hawaii_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kaveri_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/kabini_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "radeon/bonaire_vce.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/raven_vcn.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_acg_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/vega10_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris12_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_smc_sk.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris11_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_smc_sk.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/polaris10_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/fiji_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/tonga_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_k_smc.bin" for kernel module "amdgpu.ko"
Possible missing firmware "amdgpu/topaz_smc.bin" for kernel module "amdgpu.ko"

depmod....

Backing up initramfs-3.10.0-693.11.6.el7.x86_64.img to /boot/initramfs-3.10.0-693.11.6.el7.x86_64.img.old-dkms
Making new initramfs-3.10.0-693.11.6.el7.x86_64.img
(If next boot fails, revert to initramfs-3.10.0-693.11.6.el7.x86_64.img.old-dkms image)
dracut................................

DKMS: install completed.
  Installing : opencl-amdgpu-pro-17.50-511655.el7.x86_64                                                                                                       9/9
  Verifying  : libopencl-amdgpu-pro-17.50-511655.el7.x86_64                                                                                                    1/9
  Verifying  : opencl-amdgpu-pro-17.50-511655.el7.x86_64                                                                                                       2/9
  Verifying  : clinfo-amdgpu-pro-17.50-511655.el7.x86_64                                                                                                       3/9
  Verifying  : ids-amdgpu-1.0.0-511655.el7.noarch                                                                                                              4/9
  Verifying  : libopencl-amdgpu-pro-icd-17.50-511655.el7.x86_64                                                                                                5/9
  Verifying  : amdgpu-pro-core-17.50-511655.el7.noarch                                                                                                         6/9
  Verifying  : amdgpu-dkms-17.50-511655.el7.noarch                                                                                                             7/9
  Verifying  : amdgpu-core-17.50-511655.el7.noarch                                                                                                             8/9
  Verifying  : 1:libdrm-amdgpu-2.4.82-511655.el7.x86_64                                                                                                        9/9

Installed:
  opencl-amdgpu-pro.x86_64 0:17.50-511655.el7

Dependency Installed:
  amdgpu-core.noarch 0:17.50-511655.el7                 amdgpu-dkms.noarch 0:17.50-511655.el7                     amdgpu-pro-core.noarch 0:17.50-511655.el7
  clinfo-amdgpu-pro.x86_64 0:17.50-511655.el7           ids-amdgpu.noarch 0:1.0.0-511655.el7                      libdrm-amdgpu.x86_64 1:2.4.82-511655.el7
  libopencl-amdgpu-pro.x86_64 0:17.50-511655.el7        libopencl-amdgpu-pro-icd.x86_64 0:17.50-511655.el7

Complete!
[root@kvm amdgpu-pro-17.50-511655]# ./amdgpu-install --opencl=legacy --headless
