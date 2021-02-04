hero: Duplicity - A boring recipe to backup your exciting stuff. Boring is good.

# Duplicity

Intro

![Duplicity Screenshot](../images/duplicity.png)

[Duplicity](http://duplicity.nongnu.org/) backs directories by producing encrypted tar-format volumes and uploading them to a remote or local file server. Because duplicity uses librsync, the incremental archives are space efficient and only record the parts of files that have changed since the last backup. Because duplicity uses GnuPG to encrypt and/or sign these archives, they will be safe from spying and/or modification by the server.

So what does this mean for our stack? It means we can leverage Duplicity to backup all our data-at-rest to a wide variety of cloud providers, including, but not limited to:

- acd_cli
- Amazon S3
- Backblaze B2
- DropBox
- ftp
- Google Docs
- Google Drive
- Microsoft Azure
- Microsoft Onedrive
- Rackspace Cloudfiles
- rsync
- ssh/scp
- SwiftStack

## Ingredients

1. [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
2. Credentials for one of the Duplicity's supported upload destinations

## Preparation

### Setup data locations

We'll need a folder to store a docker-compose .yml file, and an associated .env file. If you're following my filesystem layout, create `/var/data/config/duplicity` (_for the config_), and `/var/data/duplicity` (_for the metadata_) as follows:

```bash
mkdir /var/data/config/duplicity
mkdir /var/data/duplicity
cd /var/data/config/duplicity
```

### (Optional) Create Google Cloud Storage bucket

I didn't already have an archival/backup provider, so I chose Google Cloud "cloud" storage for the low price-point - 0.7 cents per GB/month (_Plus you [start with \$300 credit](https://cloud.google.com/free/) even when signing up for the free tier_). You can use any destination supported by [Duplicity's URL scheme though](http://duplicity.nongnu.org/duplicity.1.html#sect7), just make sure you specify the necessary [environment variables](http://duplicity.nongnu.org/duplicity.1.html#sect6).

1. [Sign up](https://cloud.google.com/storage/docs/getting-started-console), create an empty project, enable billing, and create a bucket. Give your bucket a unique name, example "**jack-and-jills-bucket**" (_it's unique across the entire Google Cloud_)
2. Under "Storage" section > "[Settings](https://console.cloud.google.com/project/_/storage/settings)" > "Interoperability" tab > click "Enable interoperable access" and then "Create a new key" button and note both Access Key and Secret.

### Prepare environment

1. Generate a random passphrase to use to encrypt your data. **Save this somewhere safe**, without it you won't be able to restore!
2. Seriously, **save**. **it**. **somewhere**. **safe**.
3. Create duplicity.env, and populate with the following variables

```
SRC=/var/data/
DST=gs://jack-and-jills-bucket/yes-you-can-have-subdirectories
TMPDIR=/tmp
GS_ACCESS_KEY_ID=<YOUR GS ACCESS KEY>
GS_SECRET_ACCESS_KEY=<YOUR GS SECRET ACCESS KEY>

OPTIONS=--allow-source-mismatch --exclude /var/data/runtime --exclude /var/data/registry --exclude /var/data/duplicity --archive-dir=/archive
PASSPHRASE=<YOUR CHOSEN PASSPHRASE>
```

!!! note
See the [data layout reference](/reference/data_layout/) for an explanation of the included/excluded paths above.

### Run a test backup

Before we launch the automated daily backups, let's run a test backup, as follows:

```
docker run --env-file duplicity.env -it --rm -v \
/var/data:/var/data:ro -v /var/data/duplicity/tmp:/tmp -v \
/var/data/duplicity/archive:/archive tecnativa/duplicity \
/etc/periodic/daily/jobrunner
```

You should see some activity, with a summary of bytes transferred at the end.

### Run a test restore

Repeat after me: "If you don't verify your backup, **it's not a backup**".

!!! warning
Depending on what tier of storage you chose from your provider (_i.e., Google Coldline, or Amazon S3_), you may be charged for downloading data.

Run a variation of the following to confirm a file you expect to be backed up, **is** backed up. (_I used traefik.yml from the [traefik recipie](/ha-docker-swarm/traefik/), since this is likely to exist for every reader_).

```yaml
docker run --env-file duplicity.env -it --rm \
-v /var/data:/var/data:ro \
-v /var/data/duplicity/tmp:/tmp \
-v /var/data/duplicity/archive:/archive tecnativa/duplicity \
duplicity list-current-files \
\$DST | grep traefik.yml
```

Once you've identified a file to test-restore, use a variation of the following to restore it to /tmp (_from the perspective of the container - it's actually /var/data/duplicity/tmp_)

```
docker run --env-file duplicity.env -it --rm \
-v /var/data:/var/data:ro \
-v /var/data/duplicity/tmp:/tmp \
-v /var/data/duplicity/archive:/archive \
tecnativa/duplicity duplicity restore \
--file-to-restore config/traefik/traefik.yml \
\$DST /tmp/traefik-restored.yml
```

Examine the contents of /var/data/duplicity/tmp/traefik-restored.yml to confirm it contains valid data.

### Setup Docker Swarm

Now that we have confidence in our backup/restore process, let's automate it by creating a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```
version: "3"

services:
    backup:
        image: tecnativa/duplicity
        env_file: /var/data/config/duplicity/duplicity.env
        networks:
          - internal
        volumes:
          - /etc/localtime:/etc/localtime:ro
          - /var/data:/var/data:ro
          - /var/data/duplicity/tmp:/tmp
          - /var/data/duplicity/archive:/archive


networks:
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.10.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch Duplicity stack

Launch Duplicity stack by running `docker stack deploy duplicity -c <path -to-docker-compose.yml>`

Nothing will happen. Very boring. But when the cron script fires (daily), duplicity will do its thing, and backup everything in /var/data to your cloud destination.

[^1]: Automatic backup can still fail if nobody checks that it's running successfully. I'll be working on an upcoming recipe to monitor the elements of the stack, including the success/failure of duplicity jobs.
[^2]: The container provides the facility to specify an SMTP host and port, but not credentials, which makes it close to useless. As a result, I've left SMTP out of this recipe. To enable email notifications (if your SMTP server doesn't require auth), add `SMTP_HOST`, `SMTP_PORT`, `EMAIL_FROM` and `EMAIL_TO` variables to `duplicity.env`.

--8<-- "recipe-footer.md"