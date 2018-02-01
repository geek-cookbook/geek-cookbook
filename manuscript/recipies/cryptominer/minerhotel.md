# Minerhotel

!!! warning
    This is not a complete recipe - it's a component of the [cryptominer](/recipies/cryptominer/) "_uber-recipe_", but has been split into its own page to reduce complexity.

So, you have GPUs. You can mine cryptocurrency. But **what** cryptocurrency should you mine?

1. You could manually keep track of [whattomine](http://whattomine.com/), and launch/stop miners based on profitability/convenience, as you see fit.
2. You can automate the process of mining the most profitable coin based on your GPUs' capabilities and the current market prices, and do better things with your free time! (_[receiving alerts](/recipies/crytominer/monitor/), of course, if anything stops working!_)

This recipe covers option #2 😁

[Miner hotel](http://minerhotel.com/) is a collection of scripts and config files to fully automate your mining across AMD or Nvidia cards.


## Ingredients

* [Latest Minerhotel release](http://minerhotel.com/download.html) for Linux
* Time and patience

## Preparation

### Unpack Minerhotel

Unpack the minerhotel release. You can technically unpack it anywhere, but this guide, and all pre-configured miners, expect an installation at /opt/minerhotel.

### Prepare miner.config

Copy /opt/minerhotel/miner.config.example to /opt/minerhotel/miner.config, and start making changes. Here's a rundown of the variables:

* **WALLET<WHATEVER\>** : Set these WALLET variables to your wallet addresses for all the currencies you want to mine. Your miner will fail to start without the wallet variable, but it won't confirm it's a **valid** wallet. **Now, double-check to confirm the wallet is correct, and you're not just mining coins to /dev/null, or someone else's wallet!** You can either use your [exchange](/recipes/cryptominer/exchange/) wallet address or your own [wallet](/recipes/cryptominer/wallet/).
* **WORKER** : Set this to the name you'll use to define your miner in the various pools you mine. Some pools (_i.e. NiceHash_) auto-create workers based on whatever worked name you specify, whereas others (_Supernova.cc_) will refuse to authenticate you unless you've manually created the worker/password in their UI first.
* **SUPRUSER** : Set this to your supernova.cc login username (**not** your worker name) (_optional, only use this if you want to use supernova.cc_)
* **SUPRPASS** : Set this to the password you've configured within Supernova.cc for your **worker** as defined by the WORKER variable. Note that this require syou to use the **same** worker name and password across all your supernova.cc pools (_optional, only necessary if you want to use supernova.cc_)
* **MPHUSER** : Set this to your miningpoolhub login username (_optional, only necessary if you want to use [miningpoolhub.com](https://miningpoolhub.com/)_)
* **TBFUSER** : Set this to your theblocksfactory login username (_optional, only necessary if you want to use t[heblocksfactory.com](https://theblocksfactory.com/)_)
* **VERTPOOLUSER/VERTPOOLPASS** : Set these to your vertpool user/password (_optional, only necessary if you want to use [vertpool.org](http://vertpool.org/)_)

### Install services

1. Run ```/opt/minerhotel/scripts/install-services.sh``` to install the necessary services for systemd
2. Run ```/opt/minerhotel/scripts/fixmods.sh``` to correctly set the filesystem permissions for the various miner executables

!!! note
    fixmods.sh doesn't correctly set permissions on subdirectories, so until this is fixed, you also need to run ```chmod 755 /opt/minerhotel/bin/claymore/ethdcrminer64```

### Setup whattomine-linux

For the whattomine bot to select the most profitable coin to mine for **your** GPUs, you'll need to feed your cookie from https://whattomine.com

1. Start by installing [this](https://chrome.google.com/webstore/detail/cookie-inspector/jgbbilmfbammlbbhmmgaagdkbkepnijn) addon for Chrome, or [this](https://addons.mozilla.org/en-US/firefox/addon/firecookie/) addon for firefox
2. Then visit http://whattomine.com/ and tweak settings for you GPUs, power costs, etc.
3. Grab the cookie per the whattomine [README](http://git.minerhotel.com:3000/minerhotel/minerhotel/src/master/whattomine/README.md), and paste it (_about 2200 characters_) into /opt/minerhotel/whattomine/config.json
4. Ensure that only the coins/miners that you **want** are enabled in config.json - delete the others, or put a dash ("-") after the ones you want to disable. Set the service names as defined in /opt/minerhotel/services/

### Test miners

Before trusting the whattomine service to automatically launch your miners, test each one first by starting them manually, and then checking their status.

For example, to test the **miner-amd-eth-ethhash-ethermine** miner, run

1. ```systemctl start miner-amd-eth-ethhash-ethermine.service``` to start the service
2. And then watch the output by running ```journalctl -u miner-amd-eth-ethhash-ethermine -f```
3. When you're satisfied it's working correctly (_without errors and with a decent hashrate_), stop the miner again by running ```systemctl stop miner-amd-eth-ethhash-ethermine```, and move onto testing the next one.

## Serving

### Launch whattomine

Finally, run ```systemctl start minerhotel-whattomine``` and then ```journalctl -u minerhotel-whattomine -f``` to watch the output. Within a minute, you should see whattomime launching the most profitable miner, as illustrated below:

```
Jan 29 13:49:38 kvm.funkypenguin.co.nz whattomine-linux[2057]: 2018-01-29T13:49:38+1300 <INF> whattomine.js Loading whattominebot
Jan 29 13:49:38 kvm.funkypenguin.co.nz whattomine-linux[2057]: 2018-01-29T13:49:38+1300 <INF> whattomine.js Starting whattominebot now.
Jan 29 13:50:45 kvm.funkypenguin.co.nz whattomine-linux[2057]: 2018-01-29T13:50:45+1300 <INF> whattomine.js Mining Ethereum|ETH|Ethash|0.0089|0.00093|100
Jan 29 13:50:45 kvm.funkypenguin.co.nz whattomine-linux[2057]: 2018-01-29T13:50:45+1300 <INF> whattomine.js Could not find a miner for Ubiq.
Jan 29 13:51:39 kvm.funkypenguin.co.nz whattomine-linux[2057]: 2018-01-29T13:51:39+1300 <INF> whattomine.js Mining Ethereum|ETH|Ethash|0.0089|0.00094|100
Jan 29 13:51:39 kvm.funkypenguin.co.nz whattomine-linux[2057]: 2018-01-29T13:51:39+1300 <INF> whattomine.js Could not find a miner for Ubiq.
```

!!! note
    The messages about "Could not find miner" can be ignored, they indicate that one of the preferred coins on whattomine does not have a miner defined.

To make whattomine start automatically in future, run ```systemctl enable minerhotel-whattomine```

## Continue your adventure

Now, continue to the next stage of your grand mining adventure:

1. Build your [mining rig](/recipies/cryptominer/mining-rig/) 💻
2. Setup your [AMD](/recipies/cryptominer/amd-gpu/) or [Nvidia](/recipies/cryptominer/nvidia-gpu/) GPUs 🎨
3. Sign up for [mining pools](/recipies/cryptominer/mining-pool/) :swimmer:
4. Setup your miners with Miner Hotel 🏨 (_This page_)
5. Send your coins to [exchanges](/recipies/cryptominer/exchange/) or [wallets](/recipies/cryptominer/wallet/) 💹
6. [Monitor](/recipies/cryptominer/monitor/) your empire :heartbeat:
7. [Profit](/recipies/cryptominer/profit/)! 💰


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
