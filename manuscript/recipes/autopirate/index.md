---
description: A fully-featured recipe to automate finding, downloading, and organising media
---

# AutoPirate

Once the cutting edge of the "internet" (_pre-world-wide-web and mosiac days_), Usenet is now a murky, geeky alternative to torrents for file-sharing. However, it's **cool** geeky, especially if you're into having a fully automated media platform.

A good starter for the usenet scene is <https://www.reddit.com/r/usenet/>. Because it's so damn complicated, a host of automated tools exist to automate the process of finding, downloading, and managing content. The tools included in this recipe are as per the following example:

![Autopirate Screenshot](../../images/autopirate.png){ loading=lazy }

This recipe presents a method to combine these tools into a single swarm deployment, and make them available securely.

## Menu

Tools included in the AutoPirate stack are:

* [SABnzbd][sabnzbd] is the workhorse. It takes `.nzb` files as input (_manually or from [Sonarr][sonarr], [Radarr][radarr], etc_), then connects to your chosen Usenet provider, downloads all the individual binaries referenced by the .nzb, and then tests/repairs/combines/uncompresses them all into the final result - media files, to be consumed by [Plex][plex], [Emby][emby], [Komga][komga], [Calibre-Web][calibre-web]), etc.
  
* [NZBGet][nzbget] downloads data from usenet servers based on .nzb definitions. Like [SABnzbd][sabnzbd], but written in C++ and designed with performance in mind to achieve maximum download speed by using very little system resources (_this is a popular alternative to SABnzbd_)
  
* [RTorrent][rtorrent] is a popular CLI-based bittorrent client, and [ruTorrent](https://github.com/Novik/ruTorrent) is a powerful web interface for rtorrent. (_Yes, it's not Usenet, but Sonarr/Radarr will let fulfill your watchlist using either Usenet **or** torrents, so it's worth including_)
  
* [NZBHydra][nzbhydra] is a meta search for NZB indexers. It provides easy access to a number of raw and newznab based indexers. You can search all your indexers from one place and use it as indexer source for tools like [Sonarr][sonarr] or [Radarr][radarr].
  
* [Sonarr][sonarr] finds, downloads and manages TV shows

* [Radarr][radarr] finds, downloads and manages movies

* [Readarr][readarr] finds, downloads, and manages eBooks

* [Lidarr][lidarr] is an automated music downloader for NZB and Torrent. It performs the same function as [Headphones][headphones], but is written using the same(ish) codebase as [Radarr][radarr] and [Sonarr][sonarr]. It's blazingly fast, and includes beautiful album/artist art. Lidarr supports [SABnzbd][sabnzbd], [NZBGet][nzbget], Transmission, µTorrent, Deluge and Blackhole (_just like Sonarr / Radarr_)

* [Mylar][mylar] is a tool for downloading and managing digital comic books / "graphic novels"

* [Headphones][headphones] is an automated music downloader for NZB and Torrent, written in Python. It supports SABnzbd, NZBget, Transmission, µTorrent, Deluge and Blackhole.

* [Lazy Librarian][lazylibrarian] is a tool to follow authors and grab metadata for all your digital reading needs. It uses a combination of Goodreads Librarything and optionally GoogleBooks as sources for author info and book info.

* [Ombi][ombi] provides an interface to request additions to a [Plex][plex]/[Emby][emby]/[Jellyfin][jellyfin] library using the above tools

* [Jackett][jackett] works as a proxy server: it translates queries from apps (*[Sonarr][sonarr], [Radarr][radarr], [Mylar][mylar], etc*) into tracker-site-specific http queries, parses the html response, then sends results back to the requesting software.

Since this recipe is so long, and so many of the tools are optional to the final result (_i.e., if you're not interested in comics, you won't want Mylar_), I've described each individual tool on its own sub-recipe page (_below_), even though most of them are deployed very similarly.

## Ingredients

!!! summary "Ingredients"
    Already deployed:

    * [X] [Docker swarm cluster](/docker-swarm/design/) with [persistent shared storage](/docker-swarm/shared-storage-ceph/)
    * [X] [Traefik](/docker-swarm/traefik) configured per design
    * [X] DNS entry for the hostname you intend to use (*or a wildcard*), pointed to your [keepalived](/docker-swarm/keepalived/) IP

    Related:

    * [X] [Traefik Forward Auth](/docker-swarm/traefik-forward-auth/) to secure your Traefik-exposed services with an additional layer of authentication

## Preparation

### Setup data locations

We'll need a unique directories for each tool in the stack, bind-mounted into our containers, so create them upfront, in /var/data/autopirate:

```bash
mkdir /var/data/autopirate
cd /var/data/autopirate
mkdir -p {lazylibrarian,mylar,ombi,sonarr,radarr,headphones,plexpy,nzbhydra,sabnzbd,nzbget,rtorrent,jackett}
```

Create a directory for the storage of your downloaded media, i.e., something like:

```bash
mkdir /var/data/media
```

Create a user to "own" the above directories, and note the uid and gid of the created user. You'll need to specify the UID/GID in the environment variables passed to the container (in the example below, I used 4242 - twice the meaning of life).

### Secure public access

What you'll quickly notice about this recipe is that __every__ web interface is protected by an [OAuth proxy](/reference/oauth_proxy/).

Why? Because these tools are developed by a handful of volunteer developers who are focused on adding features, not necessarily implementing robust security. Most users wouldn't expose these tools directly to the internet, so the tools have rudimentary (if any) access control.

To mitigate the risk associated with public exposure of these tools (_you're on your smartphone and you want to add a movie to your watchlist, what do you do, hotshot?_), in order to gain access to each tool you'll first need to authenticate against your given OAuth provider.

This is tedious, but you only have to do it once. Each tool (Sonarr, Radarr, etc) to be protected by an OAuth proxy, requires unique configuration. I use github to provide my oauth, giving each tool a unique logo while I'm at it (make up your own random string for OAUTH2PROXYCOOKIE_SECRET)

For each tool, create `/var/data/autopirate/<tool>.env`, and set the following:

```bash
OAUTH2_PROXY_CLIENT_ID=
OAUTH2_PROXY_CLIENT_SECRET=
OAUTH2_PROXY_COOKIE_SECRET=
PUID=4242
PGID=4242
```

Create at least /var/data/autopirate/authenticated-emails.txt, containing at least your own email address with your OAuth provider. If you wanted to grant access to a specific tool to other users, you'd need a unique `authenticated-emails-<tool>.txt` which included both normal email address as well as any addresses to be granted tool-specific access.

### Setup components

#### Stack basics

**Start** with a swarm config file in docker-compose syntax, like this:

````yaml
version: '3'

services:
````

And **end** with a stanza like this:

````yaml
networks:
  traefik_public:
    external: true
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.11.0/24
````

--8<-- "reference-networks.md"
--8<-- "recipe-autopirate-toc.md"
--8<-- "recipe-footer.md"
