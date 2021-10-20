!!! danger "This recipe is a work in progress"
    This recipe is **incomplete**, and remains a work in progress.
    So... There may be errors and inaccuracies. Jump into [Discord](http://chat.funkypenguin.co.nz) if you're encountering issues 😁

# IPFS

The intention of this recipe is to provide a local IPFS cluster for the purpose of providing persistent storage for the various components of the recipes

![IPFS Screenshot](../images/ipfs.png)

Description. IPFS is a peer-to-peer distributed file system that seeks to connect all computing devices with the same system of files. In some ways, IPFS is similar to the World Wide Web, but IPFS could be seen as a single BitTorrent swarm, exchanging objects within one Git repository.

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/)

## Preparation

### Setup data locations (per-node)

Since IPFS may _replace_ ceph or glusterfs as a shared-storage provider for the swarm, we can't use sharded storage to store its persistent data. (🐔, meet :egg:)

On _each_ node, therefore run the following, to create the persistent data storage for ipfs and ipfs-cluster:

```
mkdir -p {/var/ipfs/daemon,/var/ipfs/cluster}
```

### Setup environment

ipfs-cluster nodes require a common secret, a 32-bit hex-encoded string, in order to "trust" each other, so generate one, and add it to ipfs.env on your first node, by running ```od  -vN 32 -An -tx1 /dev/urandom | tr -d ' \n'; echo```

Now on _each_ node, create ```/var/ipfs/cluster:/data/ipfs-cluster```, including both the secret, *and* the IP of docker0 interface on your hosts (_on my hosts, this is always 172.17.0.1_). We do this (_the trick with docker0)_ to allow ipfs-cluster to talk to the local ipfs daemon, per-node:

```
SECRET=<string generated above>

# Use docker0 to access daemon
IPFS_API=/ip4/172.17.0.1/tcp/5001
```

### Create docker-compose file

Yes, I know. It's not as snazzy as docker swarm. Maybe we'll get there. But this implementation uses docker-compose, so create the following (_identical_) docker-compose.yml on each node:

```yaml
version: "3"

services:
  cluster:
    image: ipfs/ipfs-cluster
    volumes:
      - /var/ipfs/cluster:/data/ipfs-cluster
    env_file: /var/data/config/ipfs/ipfs.env
    ports:
      - 9095:9095
      - 9096:9096
    depends_on:
      - daemon

  daemon:
    image: ipfs/go-ipfs
    ports:
      - 4001:4001
      - 5001:5001
      - 8080:8080
    volumes:
      - /var/ipfs/daemon:/data/ipfs
```

### Launch independent nodes

Launch all nodes independently with ```docker-compose -f ipfs.yml up```. At this point, the nodes are each running independently, unaware of each other. But we do this to ensure that service.json is populated on each node, using the IPFS_API environment variable we specified in ipfs.env. (_it's only used on the first run_)


The output looks something like this:

```
cluster_1  | 11:03:33.272  INFO    restapi: REST API (libp2p-http): ENABLED. Listening on:
cluster_1  |         /ip4/127.0.0.1/tcp/9096/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
cluster_1  |         /ip4/172.18.0.3/tcp/9096/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
cluster_1  |         /p2p-circuit/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
daemon_1   | Swarm listening on /ip4/127.0.0.1/tcp/4001
daemon_1   | Swarm listening on /ip4/172.19.0.2/tcp/4001
daemon_1   | Swarm listening on /p2p-circuit
daemon_1   | Swarm announcing /ip4/127.0.0.1/tcp/4001
daemon_1   | Swarm announcing /ip4/172.19.0.2/tcp/4001
daemon_1   | Swarm announcing /ip4/202.170.161.77/tcp/4001
daemon_1   | API server listening on /ip4/0.0.0.0/tcp/5001
daemon_1   | Gateway (readonly) server listening on /ip4/0.0.0.0/tcp/8080
daemon_1   | Daemon is ready
cluster_1  | 10:49:19.720  INFO  consensus: Current Raft Leader: QmaAiMDP7PY3CX1xqzgAoNQav5M29P5WPWVqqSBdNu1Nsp raft.go:293
cluster_1  | 10:49:19.721  INFO    cluster: Cluster Peers (without including ourselves): cluster.go:403
cluster_1  | 10:49:19.721  INFO    cluster:     - No other peers cluster.go:405
cluster_1  | 10:49:19.722  INFO    cluster: ** IPFS Cluster is READY ** cluster.go:418
```

### Pick a leader

Pick a node to be your primary node, and CTRL-C the others.

Look for a line like this in the output of the primary node:

```
/ip4/127.0.0.1/tcp/9096/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
```

You'll note several addresses listed, all ending in the same hash. None of these addresses will be your docker node's actual IP address, however, since we exposed port 9096, we can substitute your docker node's IP.

### Bootstrap the followers

On each of the non-primary nodes, run the following, replacing **IP-OF-PRIMARY-NODE** with the actual IP of the primary node, and **HASHY-MC-HASHFACE** with your own hash from primary output above.


```
docker run --rm -it -v /var/ipfs/cluster:/data/ipfs-cluster \
    --entrypoint ipfs-cluster-service ipfs/ipfs-cluster \
    daemon --bootstrap \ /ip4/IP-OF-PRIMARY-NODE/tcp/9096/ipfs/HASHY-MC-HASHFACE
```

You'll see output like this:

```
10:55:26.121  INFO    service: Bootstrapping to /ip4/192.168.31.13/tcp/9096/ipfs/QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT daemon.go:153
10:55:26.121  INFO   ipfshttp: IPFS Proxy: /ip4/0.0.0.0/tcp/9095 -> /ip4/172.17.0.1/tcp/5001 ipfshttp.go:221
10:55:26.304 ERROR   ipfshttp: error posting to IPFS: Post http://172.17.0.1:5001/api/v0/id: dial tcp 172.17.0.1:5001: connect: connection refused ipfshttp.go:708
10:55:26.622  INFO  consensus: Current Raft Leader: QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT raft.go:293
10:55:26.623  INFO    cluster: Cluster Peers (without including ourselves): cluster.go:403
10:55:26.623  INFO    cluster:     - QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT cluster.go:410
10:55:26.624  INFO    cluster:     - QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx cluster.go:410
10:55:26.625  INFO    cluster: ** IPFS Cluster is READY ** cluster.go:418
```

!!! note
    You can ignore the warnings about port 5001 refused - this is because we weren't running the ipfs daemon while bootstrapping the cluster. Its harmless.

I haven't worked out why yet, but running the bootstrap in docker-run format reset the permissions on /var/ipfs/cluster/, so look at /var/ipfs/daemon, and make the permissions of /var/ipfs/cluster the same.

You can now run ```docker-compose -f ipfs.yml up``` on the "follower" nodes, to bring your cluster online.

### Confirm cluster

docker-exec into one of the cluster containers (_it doesn't matter which one_), and run ```ipfs-cluster-ctl peers ls```

You should see output from each node member, indicating it can see its other peers. Here's my output from a 3-node cluster:

```
/ # ipfs-cluster-ctl peers ls
QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT | ef68b1437c56 | Sees 2 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/ipfs/QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT
    - /ip4/172.19.0.3/tcp/9096/ipfs/QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT
    - /p2p-circuit/ipfs/QmPrmQvW5knXLBE94jzpxvdtLSwXZeFE5DSY3FuMxypDsT
  > IPFS: QmU6buucy4FX9XqPoj4ZEiJiu7xUq2dnth5puU1rswtrGg
    - /ip4/127.0.0.1/tcp/4001/ipfs/QmU6buucy4FX9XqPoj4ZEiJiu7xUq2dnth5puU1rswtrGg
    - /ip4/172.19.0.2/tcp/4001/ipfs/QmU6buucy4FX9XqPoj4ZEiJiu7xUq2dnth5puU1rswtrGg
    - /ip4/202.170.161.75/tcp/4001/ipfs/QmU6buucy4FX9XqPoj4ZEiJiu7xUq2dnth5puU1rswtrGg
QmaAiMDP7PY3CX1xqzgAoNQav5M29P5WPWVqqSBdNu1Nsp | 6558e1bf32e2 | Sees 2 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/ipfs/QmaAiMDP7PY3CX1xqzgAoNQav5M29P5WPWVqqSBdNu1Nsp
    - /ip4/172.19.0.3/tcp/9096/ipfs/QmaAiMDP7PY3CX1xqzgAoNQav5M29P5WPWVqqSBdNu1Nsp
    - /p2p-circuit/ipfs/QmaAiMDP7PY3CX1xqzgAoNQav5M29P5WPWVqqSBdNu1Nsp
  > IPFS: QmYMUwHHsaeP2H8D2G3iXKhs1fHm2gQV6SKWiRWxbZfxX7
    - /ip4/127.0.0.1/tcp/4001/ipfs/QmYMUwHHsaeP2H8D2G3iXKhs1fHm2gQV6SKWiRWxbZfxX7
    - /ip4/172.19.0.2/tcp/4001/ipfs/QmYMUwHHsaeP2H8D2G3iXKhs1fHm2gQV6SKWiRWxbZfxX7
    - /ip4/202.170.161.77/tcp/4001/ipfs/QmYMUwHHsaeP2H8D2G3iXKhs1fHm2gQV6SKWiRWxbZfxX7
QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx | 28c13ec68f33 | Sees 2 other peers
  > Addresses:
    - /ip4/127.0.0.1/tcp/9096/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
    - /ip4/172.18.0.3/tcp/9096/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
    - /p2p-circuit/ipfs/QmbqPBLJNXWpbXEX6bVhYLo2ruEBE7mh1tfT9s6VXUzYYx
  > IPFS: QmazkAuAPpWw913HKiGsr1ief2N8cLa6xcqeAZxqDMsWmE
    - /ip4/127.0.0.1/tcp/4001/ipfs/QmazkAuAPpWw913HKiGsr1ief2N8cLa6xcqeAZxqDMsWmE
    - /ip4/172.18.0.2/tcp/4001/ipfs/QmazkAuAPpWw913HKiGsr1ief2N8cLa6xcqeAZxqDMsWmE
    - /ip4/202.170.161.96/tcp/4001/ipfs/QmazkAuAPpWw913HKiGsr1ief2N8cLa6xcqeAZxqDMsWmE
/ #
```

[^1]: I'm still trying to work out how to _mount_ the ipfs data in my filesystem in a usable way. Which is why this is still a WIP :)

--8<-- "recipe-footer.md"