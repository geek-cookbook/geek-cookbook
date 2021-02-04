# Restic

Don't be like [Cameron](http://haltandcatchfire.wikia.com/wiki/Cameron_Howe). Backup your stuff.

<iframe width="560" height="315" src="https://www.youtube.com/embed/1UtFeMoqVHQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Restic](https://restic.net/) is a backup program intended to be easy, fast, verifiable, secure, efficient, and free. Restic supports a range of backup targets, including local disk, [SFTP](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#sftp), [S3](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#amazon-s3) (*or compatible APIs like [Minio](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#minio-server)*), [Backblaze B2](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#backblaze-b2), [Azure](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#microsoft-azure-blob-storage), [Google Cloud Storage](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#google-cloud-storage), and zillions of others via [rclone](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#other-services-via-rclone).

Restic is one of the more popular open-source backup solutions, and is often [compared favorable](https://www.reddit.com/r/golang/comments/6mfe4q/a_performance_comparison_of_duplicacy_restic/dk2pkoj/?context=8&depth=9) to "freemium" products by virtue of its [licence](https://github.com/restic/restic/blob/master/LICENSE).

## Details

--8<-- "recipe-standard-ingredients.md"
    * [X] Credentials for one of Restic's [supported repositories](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)

## Preparation

### Setup data locations

We'll need a data location to bind-mount persistent config (*an exclusion list*) into our container, so create them as below:

```
mkdir -p /var/data/restic/
mkdir -p /var/data/config/restic
echo /var/data/runtime >> /var/data/restic/restic.exclude
```

!!! note
    `/var/data/restic/restic.exclude` details which files / directories to **exclude** from the backup. Per our [data layout](/reference/data_layout/), runtime data such as database files are stored in `/var/data/runtime/[recipe]`, and excluded from backups, since we can't safely backup/restore data-in-use. Databases should be backed up by taking dumps/snapshots, and backing up _these_ dumps/snapshots instead.

### Prepare environment

Create `/var/data/config/restic/restic-backup.env`, and populate with the following variables:

```
# run on startup, otherwise just on cron
RUN_ON_STARTUP=true

# when to run (TZ ensures it runs when you expect it!)
BACKUP_CRON=0 0 1 * * *
TZ=Pacific/Auckland

# restic backend/storage credentials
# see https://restic.readthedocs.io/en/stable/040_backup.html#environment-variables
#AWS_ACCESS_KEY_ID=xxxxxxxx
#AWS_SECRET_ACCESS_KEY=yyyyyyyyy
#B2_ACCOUNT_ID=xxxxxxxx
#B2_ACCOUNT_KEY=yyyyyyyyy

# will initialise the repo on startup the first time (if not already initialised)
# don't lose this password otherwise you WON'T be able to decrypt your backups!
RESTIC_REPOSITORY=<repo_name>
RESTIC_PASSWORD=<repo_password>

# what to backup (excluding anything in restic.exclude)
RESTIC_BACKUP_SOURCES=/data

# define any args to pass to the backup operation (e.g. the exclude file)
# see https://restic.readthedocs.io/en/stable/040_backup.html
RESTIC_BACKUP_ARGS=--exclude-file /restic.exclude

# define any args to pass to the forget operation (e.g. what snapshots to keep)
# see https://restic.readthedocs.io/en/stable/060_forget.html
RESTIC_FORGET_ARGS=--keep-daily 7 --keep-monthly 12
```

Create `/var/data/config/restic/restic-prune.env`, and populate with the following variables:

```
# run on startup, otherwise just on cron
RUN_ON_STARTUP=false

# when to run (TZ ensures it runs when you expect it!)
PRUNE_CRON=0 0 4 * * *
TZ=Pacific/Auckland

# restic backend/storage credentials
# see https://restic.readthedocs.io/en/stable/040_backup.html#environment-variables
#AWS_ACCESS_KEY_ID=xxxxxxxx
#AWS_SECRET_ACCESS_KEY=yyyyyyyyy
#B2_ACCOUNT_ID=xxxxxxxx
#B2_ACCOUNT_KEY=yyyyyyyyy

# will initialise the repo on startup the first time (if not already initialised)
# don't lose this password otherwise you WON'T be able to decrypt your backups!
RESTIC_REPOSITORY=<repo_name>
RESTIC_PASSWORD=<repo_password>

# prune will remove any *forgotten* snapshots, if there are some args you want
# to pass to the prune operation define them here
#RESTIC_PRUNE_ARGS=
```

!!! question "Why create two separate .env files?"
    Although there's duplication involved, maintaining 2 files for the two services within the stack keeps it clean, and allows you to potentially alter the behaviour of one service without impacting the other in future


### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3) in `/var/data/restic/restic.yml` , something like this:

--8<-- "premix-cta.md"

```yaml
version: "3.2"

services:
  backup:
    image: mazzolino/restic
    env_file: /var/data/config/restic/restic-backup.env
    hostname: docker
    volumes:
      - /var/data/restic/restic.exclude:/restic.exclude
      - /var/data:/data:ro
    deploy:
      labels:
        - "traefik.enabled=false"

  prune:
    image: mazzolino/restic
    env_file: /var/data/config/restic/restic-prune.env
    hostname: docker
    deploy:
      labels:
        - "traefik.enabled=false"

networks:
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.56.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Restic stack

Launch the Restic stack by running `docker stack deploy restic -c <path -to-docker-compose.yml>`, and watch the logs by running `docker service logs restic_backup` - you should see something like this:

```
root@raphael:~# docker service logs restic_backup  -f
restic_backup.1.9sii77j9jf0x@leonardo    | Checking configured repository '<repo_name>' ...
restic_backup.1.9sii77j9jf0x@leonardo    | Fatal: unable to open config file: Stat: stat <repo_name>/config: no such file or directory
restic_backup.1.9sii77j9jf0x@leonardo    | Is there a repository at the following location?
restic_backup.1.9sii77j9jf0x@leonardo    | <repo_name>
restic_backup.1.9sii77j9jf0x@leonardo    | Could not access the configured repository. Trying to initialize (in case it has not been initialized yet) ...
restic_backup.1.9sii77j9jf0x@leonardo    | created restic repository 66ffec75f9 at <repo_name>
restic_backup.1.9sii77j9jf0x@leonardo    |
restic_backup.1.9sii77j9jf0x@leonardo    | Please note that knowledge of your password is required to access
restic_backup.1.9sii77j9jf0x@leonardo    | the repository. Losing your password means that your data is
restic_backup.1.9sii77j9jf0x@leonardo    | irrecoverably lost.
restic_backup.1.9sii77j9jf0x@leonardo    | Repository successfully initialized.
restic_backup.1.9sii77j9jf0x@leonardo    |
restic_backup.1.9sii77j9jf0x@leonardo    |
restic_backup.1.9sii77j9jf0x@leonardo    | Scheduling backup job according to cron expression.
restic_backup.1.9sii77j9jf0x@leonardo    | new cron: 0 0 1 * * *
restic_backup.1.9sii77j9jf0x@leonardo    | (0x50fac0,0xc0000cc000)
restic_backup.1.9sii77j9jf0x@leonardo    | Stopping
restic_backup.1.9sii77j9jf0x@leonardo    | Waiting
restic_backup.1.9sii77j9jf0x@leonardo    | Exiting
```

Of note above is =="Repository successfully initialized"== - this indicates that the repository credentials passed to Restic are correct, and Restic has the necessary access to create repositories.

### Restoring data

Repeat after me : "**It's not a backup unless you've tested a restore**"

The simplest way to test your restore is to run the container once, using the variables you're already prepared, with custom arguments, as follows:

```
docker run --rm -it --name restic-restore --env-file /var/data/config/restic/restic-backup.env \
  -v /tmp/restore:/restore mazzolino/restic restore latest --target /restore
```

In my example:

```
root@raphael:~# docker run --rm -it --name restic-restore --env-file /var/data/config/restic/restic-backup.env \
>   -v /tmp/restore:/restore mazzolino/restic restore latest --target /restore
Unable to find image 'mazzolino/restic:latest' locally
latest: Pulling from mazzolino/restic
Digest: sha256:cb827c4c5e63952f8d114c87432ff12d3409a0ba4bcb52f53885dca889b1cb6b
Status: Downloaded newer image for mazzolino/restic:latest
Checking configured repository 's3:s3.amazonaws.com/restic-geek-cookbook-premix.elpenguino.be' ...
Repository found.
repository c50738d1 opened successfully, password is correct
restoring <Snapshot b5c50b19 of [/data] at 2020-06-24 23:54:27.92318041 +0000 UTC by root@docker> to /restore
root@raphael:~#
```

!!! tip "Restoring a subset of data"
    The example above restores the **entire** `/var/data` folder (*minus any exclusions*). To restore just a subset of data, add the `-i <regex>` argument, i.e. `-i plex`


[^1]: The `/var/data/restic/restic.exclude` exists to provide you with a way to exclude data you don't care to backup.
[^2]: A recent benchmark of various backup tools, including Restic, can be found [here](https://forum.duplicati.com/t/big-comparison-borg-vs-restic-vs-arq-5-vs-duplicacy-vs-duplicati/9952).
[^3]: A paid-for UI for Restic can be found [here](https://forum.restic.net/t/web-ui-for-restic/667/26).

--8<-- "recipe-footer.md"