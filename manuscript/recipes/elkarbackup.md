hero: Real heroes backup their 💾

# Elkar Backup

Don't be like [Cameron](http://haltandcatchfire.wikia.com/wiki/Cameron_Howe). Backup your stuff.

<iframe width="560" height="315" src="https://www.youtube.com/embed/1UtFeMoqVHQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

ElkarBackup is a free open-source backup solution based on RSync/RSnapshot. It's basically a web wrapper around rsync/rsnapshot, which means that your backups are just files on a filesystem, utilising hardlinks for tracking incremental changes. I find this result more reassuring than a blob of compressed, (encrypted?) data that [more sophisticated backup solutions](/recipes/duplicity/) would produce for you.

![ElkarBackup Screenshot](../images/elkarbackup.png)

## Details

--8<-- "recipe-standard-ingredients.md"

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our container, so create them in /var/data/elkarbackup:

```
mkdir -p /var/data/elkarbackup/{backups,uploads,sshkeys,database-dump}
mkdir -p /var/data/runtime/elkarbackup/db
mkdir -p /var/data/config/elkarbackup
```

### Prepare environment

Create /var/data/config/elkarbackup/elkarbackup.env, and populate with the following variables
```
SYMFONY__DATABASE__PASSWORD=password
EB_CRON=enabled
TZ='Etc/UTC'

#SMTP - Populate these if you want email notifications
#SYMFONY__MAILER__HOST=
#SYMFONY__MAILER__USER=
#SYMFONY__MAILER__PASSWORD=
#SYMFONY__MAILER__FROM=

# For mysql
MYSQL_ROOT_PASSWORD=password

#oauth2_proxy
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
```

Create ```/var/data/config/elkarbackup/elkarbackup-db-backup.env```, and populate with the following, to setup the nightly database dump.

!!! note
    Running a daily database dump might be considered overkill, since ElkarBackup can be configured to backup its own database. However, making my own backup keeps the operation of this stack consistent with **other** stacks which employ MariaDB.

    Also, did you ever hear about the guy who said "_I wish I had fewer backups"?

    No, me either :shrug:

```
# For database backup (keep 7 days daily backups)
MYSQL_PWD=<same as SYMFONY__DATABASE__PASSWORD above>
MYSQL_USER=root
BACKUP_NUM_KEEP=7
BACKUP_FREQUENCY=1d
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: "3"

services:
  db:
    image: mariadb:10.4
    env_file: /var/data/config/elkarbackup/elkarbackup.env
    networks:
      - internal
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/data/runtime/elkarbackup/db:/var/lib/mysql

  db-backup:
    image: mariadb:10.4
    env_file: /var/data/config/elkarbackup/elkarbackup-db-backup.env
    volumes:
      - /var/data/elkarbackup/database-dump:/dump
      - /etc/localtime:/etc/localtime:ro
    entrypoint: |
      bash -c 'bash -s <<EOF
      trap "break;exit" SIGHUP SIGINT SIGTERM
      sleep 2m
      while /bin/true; do
        mysqldump -h db --all-databases | gzip -c > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.sql.gz
        (ls -t /dump/dump*.sql.gz|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.sql.gz)|sort|uniq -u|xargs rm -- {}
        sleep $$BACKUP_FREQUENCY
      done
      EOF'
    networks:
    - internal

  app:
    image: elkarbackup/elkarbackup
    env_file: /var/data/config/elkarbackup/elkarbackup.env
    networks:
      - internal
    volumes:
       - /etc/localtime:/etc/localtime:ro
       - /var/data/:/var/data
       - /var/data/elkarbackup/backups:/app/backups
       - /var/data/elkarbackup/uploads:/app/uploads
       - /var/data/elkarbackup/sshkeys:/app/.ssh

   proxy:
     image: funkypenguin/oauth2_proxy
     env_file: /var/data/config/elkarbackup/elkarbackup.env
     networks:
       - traefik_public
       - internal
     deploy:
       labels:
         - traefik.frontend.rule=Host:elkarbackup.example.com
         - traefik.port=4180
     volumes:
       - /var/data/config/traefik/authenticated-emails.txt:/authenticated-emails.txt
     command: |
       -cookie-secure=false
       -upstream=http://app:80
       -redirect-url=https://elkarbackup.example.com
       -http-address=http://0.0.0.0:4180
       -email-domain=example.com
       -provider=github
       -authenticated-emails-file=/authenticated-emails.txt

networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.36.0/24
```

--8<-- "reference-networks.md"

## Serving

### Launch ElkarBackup stack

Launch the ElkarBackup stack by running ```docker stack deploy elkarbackup -c <path -to-docker-compose.yml>```

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password default password "root":

![ElkarBackup Login Screen](/images/elkarbackup-setup-1.png)

First thing you do, change your password, using the gear icon, and "Change Password" link:

![ElkarBackup Login Screen](/images/elkarbackup-setup-2.png)

Have a read of the [Elkarbackup Docs](https://docs.elkarbackup.org/docs/introduction.html) - they introduce the concept of **clients** (_hosts containing data to be backed up_), **jobs** (_what data gets backed up_), **policies** (_when is data backed up and how long is it kept_).

At the very least, you want to setup a **client** called "_localhost_" with an empty path (_i.e., the job path will be accessed locally, without SSH_), and then add a job to this client to backup /var/data, **excluding** ```/var/data/runtime``` and ```/var/data/elkarbackup/backup``` (_unless you **like** "backup-ception"_)

### Copying your backup data offsite

From the WebUI, you can download a script intended to be executed on a remote host, to backup your backup data to an offsite location. This is a **Good Idea**(tm), but needs some massaging for a Docker swarm deployment.

Here's a variation to the standard script, which I've employed:

```
#!/bin/bash

REPOSITORY=/var/data/elkarbackup/backups
SERVER=<target host member of docker swarm>
SERVER_USER=elkarbackup
UPLOADS=/var/data/elkarbackup/uploads
TARGET=/srv/backup/elkarbackup

echo "Starting backup..."
echo "Date: " `date "+%Y-%m-%d (%H:%M)"`

ssh "$SERVER_USER@$SERVER" "cd '$REPOSITORY'; find . -maxdepth 2 -mindepth 2" | sed s/^..// | while read jobId
do
    echo Backing up job $jobId
    mkdir -p $TARGET/$jobId 2>/dev/null
    rsync -aH --delete "$SERVER_USER@$SERVER:$REPOSITORY/$jobId/" $TARGET/$jobId
done

echo Backing up uploads
rsync -aH --delete "$SERVER_USER@$SERVER":"$UPLOADS/" $TARGET/uploads

USED=`df -h . | awk 'NR==2 { print $3 }'`
USE=`df -h . | awk 'NR==2 { print $5 }'`
AVAILABLE=`df -h . | awk 'NR==2 { print $4 }'`

echo "Backup finished succesfully!"
echo "Date: " `date "+%Y-%m-%d (%H:%M)"`
echo ""
echo "**** INFO ****"
echo "Used disk space: $USED ($USE)"
echo "Available disk space: $AVAILABLE"
echo ""
```

!!! note
    You'll note that I don't use the script to create a mysql dump (_since Elkar is running within a container anyway_), rather I just rely on the database dump which is made nightly into ```/var/data/elkarbackup/database-dump/```

### Restoring data

Repeat after me : "**It's not a backup unless you've tested a restore**"

!!! note
    I had some difficulty making restoring work well in the webUI. My attempts to "Restore to client" failed with an SSH error about "localhost" not found. I **was** able to download the backup from my web browser, so I considered it a successful restore, since I can retrieve the backed-up data either from the webUI or from the filesystem directly.

To restore files form a job, click on the "Restore" button in the WebUI, while on the **Jobs** tab:

![ElkarBackup Login Screen](/images/elkarbackup-setup-3.png)

This takes you to a list of backup names and file paths. You can choose to download the entire contents of the backup from your browser as a .tar.gz, or to restore the backup to the client. If you click on the **name** of the backup, you can also drill down into the file structure, choosing to restore a single file or directory.

[^1]: If you wanted to expose the ElkarBackup UI directly, you could remove the oauth2_proxy from the design, and move the traefik_public-related labels directly to the app service. You'd also need to add the traefik_public network to the app service.
[^2]: The original inclusion of ElkarBackup was due to the efforts of @gpulido in our [Discord server](http://chat.funkypenguin.co.nz). Thanks Gabriel!

--8<-- "recipe-footer.md"