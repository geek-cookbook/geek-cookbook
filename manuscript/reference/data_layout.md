# Data layout

The applications deployed in the stack utilize a combination of data-at-rest (_static config, files, etc_) and runtime data (_live database files_). The realtime data can't be [backed up](/recipies/duplicity) with a simple copy-paste, so where we employ databases, we also include containers to perform a regular export of database data to a filesystem location.

So that we can confidently backup all our data, I've setup a data layout as follows:

## Configuration data

Configuration data goes into /var/data/config/[recipe name], and is typically only a docker-compose .yml, and a .env file

## Runtime data

Realtime data (typically database files or files-in-use) are stored in /var/data/realtime/[recipe-name], and are **excluded** from backup (_They change constantly, and cannot be safely restored_).

## Static data

Static data goes into /var/data/[recipe name], and includes anything that can be safely backed up while a container is running. This includes database exports of the runtime data above.


## Chef's Notes

### Tip your waiter (donate) 👏

Did you receive excellent service? Want to make your waiter happy? (_..and support development of current and future recipes!_) See the [support](/support/) page for (_free or paid)_ ways to say thank you! 👏

### Your comments? 💬
