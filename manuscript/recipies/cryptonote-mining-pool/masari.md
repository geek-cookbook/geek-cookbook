# Masari Mining Pool

[Cryptocurrency miners](/recipies/cryptominer) will "pool" their GPU resources ("_hashpower_") into aggregate "_mining pools_", so that by the combined effort of all the miners, the pool will receive a reward for the blocks "mined" into the blockchain, and this reward will be distributed among the miners.

![Masari Pool Screenshot](../images/masari-pool.png)

This recipe illustrates how to build a mining pool for [Masari](https://getmasari.org), one of many [CryptoNote](https://cryptonote.org/) [currencies](https://cryptonote.org/coins) (_which include [Monero](https://www.coingecko.com/en/coins/monero)_), but the principles can be applied to most mineable coins.

The end result is a mining pool which looks like this: https://msr.heigh-ho.funkypenguin.co.nz/

!!! question "Isn't this just a copy/paste of your Masari Pool Recipe?"

    Why yes. Yes it is :) But it's adjusted for Masari, which uses different containers and wallet binary names, and it's running the improved [cryptonote-nodejs-pool software](https://github.com/dvandal/cryptonote-nodejs-pool), which is common to all the [cryptonote-mining-pool](/recipies/criptonote-mining-pool/) recipies!

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. DNS entry for the hostnames (_pool and api_) you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP
4. At least 16GB disk space (12GB used, 4GB for future growth)

## Preparation

### Create user account

The Masari pool elements won't (_and shouldn't_) run as root, but they'll need access to write data to some parts of the filesystem (_like logs, etc_).

To manage access control, we'll want to create a local user on **each docker node** with the same UID.

```
useradd -u 3507 masari-pool
```

### Setup Redis


The pool uses Redis for in-memory and persistent storage. This comes in handy for the Docker Swarm deployment, since while the various pool modules weren't _designed_ to run as microservices, the fact that they all rely on Redis for data storage makes this possible.

!!! warning "Playing it safe"

    Be aware that by default, Redis stores some data **only** in memory, and writes to the filesystem at default intervals (_can be up to 5 minutes by default_). Given we don't **want** to loose 5 minutes of miner's data if we restart Redis (_what happens if we found a block during those 5 minutes but haven't paid any miners yet?_), we want to ensure that Redis runs in "appendonly" mode, which ensures that every change is immediately written to disk.

    We also want to make sure that we retain all Redis logs persistently (_We're dealing with people's cryptocurrency here, it's a good idea to keep persistent logs for debugging/auditing_)

Create directories to hold Redis data. We use separate directories for future flexibility - One day, we may want to backup the data but not the logs, or move the data to an SSD partition but leave the logs on slower, cheaper disk.

```
mkdir -p /var/data/masari-pool/redis/config
mkdir -p /var/data/masari-pool/redis/data
mkdir -p /var/data/masari-pool/redis/logs
chown masari-pool /var/data/masari-pool/redis/data
chown masari-pool /var/data/masari-pool/redis/logs
```

Create **/var/data/masari-pool/redis/config/redis.conf** using http://download.redis.io/redis-stable/redis.conf as a guide. The following are the values I changed from default on my deployment (_but I'm not a Redis expert!_):

```
appendonly yes
appendfilename "appendonly.aof"
loglevel notice
logfile "/logs/redis.log"
protected-mode no
```

I also had to **disable** the following line, by commenting it out (_thus ensuring Redis container will respond to the other containers_):

```
bind 127.0.0.1
```

### Setup Nginx

We'll run a simple Nginx container to serve the static front-end of the web UI.

The simplest way to get the frontend is just to clone the upstream masari-pool repo, and mount the "/website" subdirectory into Nginx.

```
git clone https://github.com/turtlecoin/turtle-pool.git /var/data/masari-pool/nginx/
```

Edit **/var/data/masari-pool/nginx/website/config.js**, and change at least the following:

```
var api = "https://<CHOOSE A FQDN TO USE FOR YOUR API>";
var poolHost = "<SET TO THE PUBLIC DNS NAME FOR YOUR POOL SERVER";
```

### Setup Masari daemon

The first thing we'll need to participate in the great and powerful Masari network is a **node**. The node is responsible for communicating with the rest of the nodes in the blockchain, allowing our miners to receive new blocks to try to find.

Create directories to hold the blockchain data for all 3 daemons:

```
mkdir -p /var/data/runtime/masari-pool/daemon/
```

### Setup Masari wallet

Our pool needs a wallet to be able to (a) receive rewards for blocks discovered, and (b) pay out our miners for their share of the reward.

Create directories to hold wallet data

```
mkdir -p /var/data/masari-pool/wallet/config
mkdir -p /var/data/masari-pool/wallet/container
mkdir -p /var/data/masari-pool/wallet/logs
chown -R masari-pool /var/data/masari-pool/wallet/container
chown -R masari-pool /var/data/masari-pool/wallet/logs
```

Now create the initial wallet. You'll want to secure your wallet password, so the command below will **prompt** you for the key (no output from the prompt), and insert it into an environment variable. This means that the key won't be stored in plaintext in your bash history!

```
read PASS
```

After having entered your password (you can confirm by running ```env | grep PASS```), run the following to run the wallet daemon _once_, with the instruction to create a new wallet container:

```
docker run \
 -v /var/data/masari-pool/wallet/wallet:/wallet \
 --rm -ti --entrypoint /usr/local/bin/masari-wallet-cli funkypenguin/masari \
 --password $PASS \
 --generate-new-wallet /wallet/wallet \
 --mnemonic-language English \
 --command do-nothing-and-exit
```

You'll get a lot of output. The following are relevant lines from a successful run with the extra stuff stripped out:

```
[root@ds3 ~]# docker run \
>  -v /var/data/masari-pool/wallet/wallet:/wallet \
>  --rm -ti --entrypoint /usr/local/bin/masari-wallet-cli funkypenguin/masari \
>  --password $PASS \
>  --generate-new-wallet /wallet/wallet \
>  --mnemonic-language English \
>  --command do-nothing-and-exit
This is the command line masari wallet. It needs to connect to a masari daemon to work correctly.

Masari 'Classy Caiman' (v0.2.4.1-release)
Logging to /usr/local/bin/masari-wallet-cli.log
Generated new wallet: 5oUpENoBjxvjEq9Rq18cQHVhvBNGwJi9vfr36Uf5cVjx5JZNUWdHDPuFxt5sVBzuMsJcsNNEmQqvnV6UfiGuBgg4HogmEcZ
View key: d7b9d73856ba7b8e43010e3e8201d17e3aee90d2a3792439c179553229e9780f
**********************************************************************
Your wallet has been generated!
To start synchronizing with the daemon, use the "refresh" command.
Use the "help" command to see the list of available commands.
Use "help <command>" to see a command's documentation.
Always use the "exit" command when closing masari-wallet-cli to save
your current session's state. Otherwise, you might need to synchronize
your wallet again (your wallet keys are NOT at risk in any case).


NOTE: the following 25 words can be used to recover access to your wallet. Write them down and store them somewhere safe and secure. Please do not store them in your email or on file storage services outside of your immediate control.

ecstatic boil cycling bowling jeopardy fawns loudly baby
nuance token withdrawn nifty ramped taken donuts irritate
sack tedious fishing kangaroo toffee video lyrics mohawk kangaroo
**********************************************************************
Error: Unknown command: do-nothing-and-exit
[root@ds3 ~]#
```

Take careful note of your wallet password, public view key, and wallet address

Create **/var/data/masari-pool/wallet/config/wallet.conf**, containing the following:

```
wallet-file = /wallet/wallet
password = <ENTER YOUR CONTAINER PASSWORD HERE>
rpc-password = <CHOOSE A PASSWORD TO ALLOW POOL TO TALK TO WALLET>
log-file = /dev/stdout
log-level = 1
daemon-host = daemon
rpc-bind-port = 38082
```

Set permissions appropriately:

```
chown masari-pool /var/data/masari-pool/wallet/ -R
```


### Setup Masari mining pool

Following the convention we've set above, create directories to hold pool data:

```
mkdir -p /var/data/masari-pool/pool/config
mkdir -p /var/data/masari-pool/pool/logs
chown -R masari-pool /var/data/masari-pool/pool/logs
```

Now create **/var/data/masari-pool/pool/config/config.json**, using https://github.com/masaricoin/masari-pool/blob/master/config.json as a guide, and adjusting at least the following:

Send logs to /logs/, so that they can potentially be stored / backed up separately from the config:

```
"logging": {
    "files": {
        "level": "debug",
        "directory": "/logs",
        "flushInterval": 5
    },
```

Set the "poolAddress" field to your wallet address
```
"poolServer": {
    "enabled": true,
    "clusterForks": "auto",
    "poolAddress": "<SET THIS TO YOUR WALLET ADDRESS GENERATED ABOVE>",
```

Add the "host" value to the api section, since our API will run on its own container, and choose a password you'll use for the webUI admin page

```
"api": {
    "enabled": true,
    "hashrateWindow": 600,
    "updateInterval": 5,
    "host": "pool-api",
    "port": 8117,
    "blocks": 30,
    "payments": 30,
    "password": "<PASSWORD FOR ADMIN PAGE ACCESS>"
```

Set the host value for the daemon:

```
"daemon": {
    "host": "daemon",
    "port": 38081
},
```

Set the host value for the wallet, and set your container password (_you recorded it earlier, remember?_)

```
"wallet": {
    "host": "wallet",
    "port": 38082,
    "password": "<SET ME TO YOUR WALLET RPC PASSWORD>"
},
```

Set the host value for Redis:

```
"redis": {
    "host": "redis",
    "port": 6379
},
```

That's it! The above config files mean each element of the pool will be able to communicate with the other elements within the docker swarm, by name.





### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

!!! tip
        I share (_with my [patreon patrons](https://www.patreon.com/funkypenguin)_) a private "_premix_" git repository, which includes necessary docker-compose and env files for all published recipes. This means that patrons can launch any recipe with just a ```git pull``` and a ```docker stack deploy``` 👍


```
version: '3'

services:
  daemon:
    image: funkypenguin/masaricoind
    volumes:
      - /var/data/runtime/masari-pool/daemon/1:/var/lib/masaricoind/
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
      - traefik_public
    ports:
      - 11897:11897
      labels:
        - traefik.frontend.rule=Host:explorer.trtl.heigh-ho.funkypenguin.co.nz
        - traefik.docker.network=traefik_public
        - traefik.port=11898

  daemon-failsafe1:
    image: funkypenguin/masaricoind
    volumes:
      - /var/data/runtime/masari-pool/daemon/failsafe1:/var/lib/masaricoind/
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal

  daemon-failsafe2:
    image: funkypenguin/masaricoind
    volumes:
      - /var/data/runtime/masari-pool/daemon/failsafe2:/var/lib/masaricoind/
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal

  pool-pool:
    image: funkypenguin/turtle-pool
    volumes:
      - /var/data/masari-pool/pool/config:/config:ro
      - /var/data/masari-pool/pool/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
    ports:
      - 3333:3333
      - 5555:5555
      - 7777:7777
    entrypoint: |
      node init.js -module=pool -config=/config/config.json

  pool-api:
    image: funkypenguin/turtle-pool
    volumes:
      - /var/data/masari-pool/pool/config:/config:ro
      - /var/data/masari-pool/pool/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:api.trtl.heigh-ho.funkypenguin.co.nz
        - traefik.docker.network=traefik_public
        - traefik.port=8117
    entrypoint: |
      node init.js -module=api -config=/config/config.json

  pool-unlocker:
    image: funkypenguin/turtle-pool
    volumes:
      - /var/data/masari-pool/pool/config:/config:ro
      - /var/data/masari-pool/pool/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
    entrypoint: |
      node init.js -module=unlocker -config=/config/config.json

  pool-payments:
    image: funkypenguin/turtle-pool
    volumes:
      - /var/data/masari-pool/pool/config:/config:ro
      - /var/data/masari-pool/pool/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
    entrypoint: |
      node init.js -module=payments -config=/config/config.json

  pool-charts:
    image: funkypenguin/turtle-pool
    volumes:
      - /var/data/masari-pool/pool/config:/config:ro
      - /var/data/masari-pool/pool/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
    entrypoint: |
      node init.js -module=chartsDataCollector -config=/config/config.json

  wallet:
    image: funkypenguin/masari
    volumes:
      - /var/data/masari-pool/wallet/config:/config:ro
      - /var/data/masari-pool/wallet/container:/container
      - /var/data/masari-pool/wallet/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
    entrypoint: |
      walletd --config /config/wallet.conf | tee /logs/walletd.log

  redis:
    volumes:
      - /var/data/masari-pool/redis/config:/config:ro
      - /var/data/masari-pool/redis/data:/data
      - /var/data/masari-pool/redis/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    image: redis
    entrypoint: |
      redis-server /config/redis.conf
    networks:
      - internal

  nginx:
    volumes:
      - /var/data/masari-pool/nginx/website:/usr/share/nginx/html:ro
      - /etc/localtime:/etc/localtime:ro
    image: nginx
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:trtl.heigh-ho.funkypenguin.co.nz
        - traefik.docker.network=traefik_public
        - traefik.port=80

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.21.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.


## Serving

### Launch the Turtle! 🐢

Launch the Turtle pool stack by running ```docker stack deploy masari-pool -c <path -to-docker-compose.yml>```, and then run ```"```docker stack ps masari-pool``` to ensure the stack has come up properly. (_See [troubleshooting](/reference/troubleshooting) if not_)

The first thing that'll happen is that Masarid will start syncing the blockchain from the bootstrap data. You can watch this happening with ```docker service logs masari-pool_daemon -f```. While the daemon is syncing, it won't respond to requests, so walletd, the pool, etc will be non-functional.

You can watch the various elements of the pool doing their thing, by running ```tail -f /var/data/masari-pool/pool/logs/*.log```

### So how do I mine to it?

That.. is another recipe. Start with the "[CryptoMiner](/recipes/cryptominer/)" uber-recipe for GPU/rig details, grab a copy of xmr-stack (_patched for the forked Masari_) from https://github.com/masaricoin/trtl-stak/releases, and follow your nose. Jump into the Masari discord (_below_) #mining channel for help.

### What to do if it breaks?

Masari is a baby cryptocurrency. There are scaling issues to solve, and large amounts components of this recipe are under rapid development. So, elements may break/change in time, and this recipe itself is a work-in-progress.

Jump into the [Masari Discord server](http://chat.masaricoin.lol/) to ask questions, contribute, and send/receive some TRTL tips!

## Chef's Notes

1. Because Docker Swarm performs ingress NAT for its load-balanced "routing mesh", the source address of inbound miner traffic is rewritten to a (_common_) docker node IP address. This means it's [not possible to determine the actual source IP address](https://github.com/moby/moby/issues/25526) of a miner. Which, in turn, means that any **one** misconfigured miner could trigger an IP ban, and lock out all other miners for 5 minutes at a time.

Two possible solutions to this are (1) disable banning, or (2) update the pool banning code to ban based on a combination of IP address and miner wallet address. I'll be working on a change to implement #2 if this becomes a concern.

2. The traefik labels in the docker-compose are to permit automatic LetsEncrypt SSL-protected proxying of your pool UI and API addresses.

3. After a [power fault in my datacenter caused daemon DB corruption](https://www.reddit.com/r/TRTL/comments/8jftzt/funky_penguin_nz_mining_pool_down_with_daemon/), I added a second daemon, running in parallel to the first. The failsafe daemon runs once an hour, syncs with the running daemons, and shuts down again, providing a safely halted version of the daemon DB for recovery.

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

Also, you could send me some :masari: ❤️ to _TRTLv2qCKYChMbU5sNkc85hzq2VcGpQidaowbnV2N6LAYrFNebMLepKKPrdif75x5hAizwfc1pX4gi5VsR9WQbjQgYcJm21zec4_

### Your comments? 💬
