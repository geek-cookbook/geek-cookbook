# Athena Mining Pool

[Cryptocurrency miners](/recipies/cryptominer) will "pool" their GPU resources ("_hashpower_") into aggregate "_mining pools_", so that by the combined effort of all the miners, the pool will receive a reward for the blocks "mined" into the blockchain, and this reward will be distributed among the miners.

![Athena Pool Screenshot](../../images/athena-mining-pool.png)

This recipe illustrates how to build a mining pool for [Athena](https://getathena.org), a newborn [CryptoNote](https://cryptonote.org/) [currency](https://cryptonote.org/coins) recently forked from [TurtleCoin](https://turtlecoin.lol)

The end result is a mining pool which looks like this: https://athx.heigh-ho.funkypenguin.co.nz/

!!! question "Isn't this just a copy/paste of your [TurtleCoin Pool Recipe](/recipies/turtle-pool/)?"

    Why yes. Yes it is :) But it's adjusted for Athena, which uses different containers and wallet binary names, and it's running the improved [cryptonote-nodejs-pool software](https://github.com/dvandal/cryptonote-nodejs-pool), which is common to all the [cryptonote-mining-pool](/recipies/criptonote-mining-pool/) recipies!

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. [Traefik](/ha-docker-swarm/traefik) configured per design
3. DNS entry for the hostnames (_pool and api_) you intend to use, pointed to your [keepalived](ha-docker-swarm/keepalived/) IP
4. At least 8GB disk space (2.5GB used, 6.5GB for future growth)

## Preparation

### Create user account

The Athena pool elements won't (_and shouldn't_) run as root, but they'll need access to write data to some parts of the filesystem (_like logs, etc_).

To manage access control, we'll want to create a local user on **each docker node** with the same UID.

```
useradd -u 3508 athena-pool
```

### Setup Redis


The pool uses Redis for in-memory and persistent storage.

!!! warning "Playing it safe"

    Be aware that by default, Redis stores some data **only** in memory, and writes to the filesystem at default intervals (_can be up to 5 minutes by default_). Given we don't **want** to loose 5 minutes of miner's data if we restart Redis (_what happens if we found a block during those 5 minutes but haven't paid any miners yet?_), we want to ensure that Redis runs in "appendonly" mode, which ensures that every change is immediately written to disk.

    We also want to make sure that we retain all Redis logs persistently (_We're dealing with people's cryptocurrency here, it's a good idea to keep persistent logs for debugging/auditing_)

Create directories to hold Redis data. We use separate directories for future flexibility - One day, we may want to backup the data but not the logs, or move the data to an SSD partition but leave the logs on slower, cheaper disk.

```
mkdir -p /var/data/athena-pool/redis/config
mkdir -p /var/data/athena-pool/redis/data
mkdir -p /var/data/athena-pool/redis/logs
chown athena-pool /var/data/athena-pool/redis/data
chown athena-pool /var/data/athena-pool/redis/logs
```

Create **/var/data/athena-pool/redis/config/redis.conf** using http://download.redis.io/redis-stable/redis.conf as a guide. The following are the values I changed from default on my deployment (_but I'm not a Redis expert!_):

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

The simplest way to get the frontend is just to clone the upstream athena-pool repo, and mount the "/website" subdirectory into Nginx.

```
git clone https://github.com/funkypenguin/cryptonote-nodejs-pool.git /var/data/athena-pool/nginx
```

Edit **/var/data/athena-pool/nginx/website/config.js**, and change at least the following:

```
var api = "https://<CHOOSE A FQDN TO USE FOR YOUR API>";
var blockchainExplorer = "http://explorer.athx.org/?hash={id}#blockchain_block";
var transactionExplorer = "http://explorer.athx.org/?hash={id}#blockchain_transaction";
```

And optionally, set the following:
```
var telegram = "https://t.me/YourPool";
var discord = "https://chat.funkypenguin.co.nz";
```

### Setup Athena daemon

The first thing we'll need to participate in the great and powerful Athena network is a **node**. The node is responsible for communicating with the rest of the nodes in the blockchain, allowing our miners to receive new blocks to try to find.

Create a directory to hold the blockchain data:

```
mkdir -p /var/data/runtime/athena-pool/daemon/
```

### Setup Athena wallet

Our pool needs a wallet to be able to (a) receive rewards for blocks discovered, and (b) pay out our miners for their share of the reward.

!!! note
    Under Athena, "walletd" was renamed to "services". I don't know why, but I've updated this recipe to reflect this.

Create directories to hold wallet data:

```
mkdir -p /var/data/athena-pool/services/config
mkdir -p /var/data/athena-pool/services/services
mkdir -p /var/data/athena-pool/services/logs
chown -R athena-pool /var/data/athena-pool/wallet/services
chown -R athena-pool /var/data/athena-pool/wallet/logs
```

Now create the initial wallet. You'll want to secure your wallet password, so the command below will **prompt** you for the key (no output from the prompt), and insert it into an environment variable. This means that the key won't be stored in plaintext in your bash history!

```
read PASS
```

After having entered your password (you can confirm by running ```env | grep PASS```), run the following to run the wallet daemon _once_, with the instruction to create a new wallet container:

```
docker run \
 -v /var/data/athena-pool/wallet/container:/container \
 --rm -ti --entrypoint /usr/local/bin/services funkypenguin/athena \
 --container-file /container/wallet.container \
 --container-password $PASS \
 --generate-container
```

You'll get a lot of output. The following are relevant lines from a successful run with the extra stuff stripped out:

```
2018-May-01 11:14:57.662664 INFO    walled v0.6.4 ()
2018-May-01 11:14:59.868087 INFO    Generating new wallet
2018-May-01 11:14:59.919178 INFO    Container initialized with view secret key, public view key <your view public key will be here>
2018-May-01 11:14:59.920932 INFO    New wallet added athena<your wallet's public address>, creation timestamp 0
2018-May-01 11:14:59.932367 INFO    Container shut down
2018-May-01 11:14:59.932419 INFO    Loading container...
2018-May-01 11:14:59.961814 INFO    Consumer added, consumer 0x55b0fb5bc070, count 1
2018-May-01 11:14:59.961996 INFO    Starting...
2018-May-01 11:14:59.962173 INFO    Container loaded, view public key <your view public key will be here>, wallet count 1, actual balance 0.00, pending balance 0.00
2018-May-01 11:14:59.962508 INFO    New wallet is generated. Address: TRTL<your wallet's public address>
2018-May-01 11:14:59.962581 INFO    Saving container...
2018-May-01 11:14:59.962683 INFO    Stopping...
2018-May-01 11:14:59.962862 INFO    Stopped
```

Take careful note of your wallet password, public view key, and wallet address

Create **/var/data/athena-pool/services/config/services.conf**, containing the following:

```
bind-address = 0.0.0.0
container-file = /services/wallet.container
container-password = <ENTER YOUR CONTAINER PASSWORD HERE>
rpc-password = <CHOOSE A PASSWORD TO ALLOW POOL TO TALK TO WALLET>
log-file = /dev/stdout
log-level = 3
daemon-address = daemon
```

Set permissions appropriately:

```
chown athena-pool /var/data/athena-pool/services/ -R
```


### Setup Athena mining pool

Following the convention we've set above, create directories to hold pool data:

```
mkdir -p /var/data/athena-pool/pool/config
mkdir -p /var/data/athena-pool/pool/logs
chown -R athena-pool /var/data/athena-pool/pool/logs
```

Now create **/var/data/athena-pool/pool/config/config.json**, copying https://github.com/funkypenguin/cryptonote-nodejs-pool/blob/master/config_examples/monero.json, and modifying according to https://github.com/athena-network/athena-pool/blob/master/config.json, adjusting at least the following:

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
    "port": 8117,
    "blocks": 30,
    "payments": 30,
    "password": "<PASSWORD FOR ADMIN PAGE ACCESS>"
```

Set the host value for the daemon:

```
"daemon": {
    "host": "daemon",
    "port": 11898
},
```

Set the host value for the wallet, and set your container password (_you recorded it earlier, remember?_)

```
"wallet": {
    "host": "services",
    "port": 8079,
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
    image: funkypenguin/athena
    volumes:
      - /var/data/runtime/athena-pool/daemon/:/root/.athena
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal

  services:
    image: funkypenguin/athena
    volumes:
      - /var/data/athena-pool/services/config:/config:ro
      - /var/data/athena-pool/services/services:/services
      - /var/data/athena-pool/services/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
    entrypoint: |
      services --config /config/services.conf | tee /logs/athena-services.log

  pool:
    image: funkypenguin/cryptonote-nodejs-pool
    volumes:
      - /var/data/athena-pool/pool/config:/config:ro
      - /var/data/athena-pool/pool/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    networks:
      - internal
      - traefik_public
    ports:
      - 3335:3335
      - 5557:5557
      - 7779:7779
    entrypoint: |
      node init.js -config=/config/athena.json
    deploy:
      labels:
        - traefik.frontend.rule=Host:api.athx.heigh-ho.funkypenguin.co.nz
        - traefik.docker.network=traefik_public
        - traefik.port=8117

  redis:
    volumes:
      - /var/data/athena-pool/redis/config:/config:ro
      - /var/data/athena-pool/redis/data:/data
      - /var/data/athena-pool/redis/logs:/logs
      - /etc/localtime:/etc/localtime:ro
    image: redis
    entrypoint: |
      redis-server /config/redis.conf
    networks:
      - internal

  nginx:
    volumes:
      - /var/data/athena-pool/nginx/website:/usr/share/nginx/html:ro
      - /etc/localtime:/etc/localtime:ro
    image: nginx
    networks:
      - internal
      - traefik_public
    deploy:
      labels:
        - traefik.frontend.rule=Host:athx.heigh-ho.funkypenguin.co.nz
        - traefik.docker.network=traefik_public
        - traefik.port=80

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.26.0/24
```

!!! note
    Setup unique static subnets for every stack you deploy. This avoids IP/gateway conflicts which can otherwise occur when you're creating/removing stacks a lot. See [my list](/reference/networks/) here.


## Serving

### Athena is a go!

Launch the Athena pool stack by running ```docker stack deploy athena-pool -c <path -to-docker-compose.yml>```, and then run ```"```docker stack ps athena-pool``` to ensure the stack has come up properly. (_See [troubleshooting](/reference/troubleshooting) if not_)

The first thing that'll happen is that Athena will start syncing the blockchain. You can watch this happening with ```docker service logs athena-pool_daemon -f```. While the daemon is syncing, it won't respond to requests, so services, the pool, etc will be non-functional.

You can watch the various elements of the pool doing their thing, by running ```tail -f /var/data/athena-pool/pool/logs/*.log```

### So how do I mine to it?

That.. is another recipe. Start with the "[CryptoMiner](/recipes/cryptominer/)" uber-recipe for GPU/rig details, grab a copy of [xmr-stack](https://github.com/fireice-uk/xmr-stak), use the same parameters as TurtleCoin, and follow your nose. Jump into the Athena discord (_below_) #mining channel for help.

### What to do if it breaks?

Athena is a newborn cryptocurrency, and the [destiny of the coin is not yet clear](https://github.com/athena-network/athx-research/issues/1).

Jump into the [Athena Discord server](http://chat.athx.org) to ask questions, contribute.

## Chef's Notes

1. Because Docker Swarm performs ingress NAT for its load-balanced "routing mesh", the source address of inbound miner traffic is rewritten to a (_common_) docker node IP address. This means it's [not possible to determine the actual source IP address](https://github.com/moby/moby/issues/25526) of a miner. Which, in turn, means that any **one** misconfigured miner could trigger an IP ban, and lock out all other miners for 5 minutes at a time.

Two possible solutions to this are (1) disable banning, or (2) update the pool banning code to ban based on a combination of IP address and miner wallet address. I'll be working on a change to implement #2 if this becomes a concern.

2. The traefik labels in the docker-compose are to permit automatic LetsEncrypt SSL-protected proxying of your pool UI and API addresses.

3. Astute readers will note that although I set permissions to the "athena-pool" user above, those permissions are not **actually** enforced in the .yml file (yet)

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

Also, you could send me some ATHX ❤️ to _athena2i8SmWUGQffz6sXEdvCDawkDQvz2gdf9iBnepU999j3fUzuschJiKrow2GCTEsd5cWnk3sz2iz59WSr6NVdpvDXPbX6qj4g_

### Your comments? 💬
