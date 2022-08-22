---
title: Review / Immich - a self-hosted Google Photos alternative
description: Immich is a polished and functional replacement for Google Photos
upstream_version: v1.19.1
upstream_repo: https://github.com/immich-app/immich
review_latest_change: Initial review!
---

# I'm defz going to replace Google Photos with Immich!

| Review details      |                           |
| ----------- | ------------------------------------ |
| :material-calendar-check: Last updated       | *{{ git_revision_date_localized }}* |
| :octicons-number-24: Reviewed version       | *[{{ page.meta.upstream_version }}]({{ page.meta.upstream_repo }})* |

Immich is a promising self-hosted alternative to Google Photos. Its UI and features are clearly heavily inspired by Google Photos, and like [Photoprism][photoprism], Immich uses tensorflow-based machine learning to auto-tag your photos!

!!! warning "Pre-production warning"
    The developer makes it abundantly clear that Immich is under heavy development (*although it's covered by "wife-insurance"[^1]*), features and APIs may change, and all your photos may be lost, or (worse) auto-shared with your :dragon_face: mother-in-law! Take due care :wink:

I'm personally excited about Immich because I've recently been debating how to migrate from Google Photos, in which I'm hitting my 15GB storage limit.

![Immich Screenshot](/images/immich.jpg){ loading=lazy }

Immich is a bit of an outlier in the self-hosted application space in terms of its maturity.. the [repository](https://github.com/immich-app/immich) currently states that it's **not** production-ready, but it's already got both an Android and iOS app available in the respective app stores.

Two things stand out to me here - first off, the developer actively tries to discourage users from relying on the app for anything other than testing, and secondly, by investing in the mobile apps / app stores (*which come with a cost*), they're clearly thinking long-term and are committed to the project.

## Immich Features

Here are the current Immich features, which I scraped directly from the repo. As you'll note, the mobile apps mostly have parity with the web app, other than administrative functions, and even have some extra features, like search..

|  | Mobile | Web |
| - | - | - |
| Upload and view videos and photos | Yes | Yes
| Auto backup when app is opened | Yes | N/A
| Selective album(s) for backup | Yes | N/A
| Download photos and videos to local device | Yes | Yes
| Multi-user support | Yes | Yes
| Album | No | Yes
| Shared Albums | Yes | Yes
| Quick navigation with draggable scrollbar | Yes | Yes
| Support RAW (HEIC, HEIF, DNG, Apple ProRaw) | Yes | Yes
| Metadata view (EXIF, map) | Yes | Yes
| Search by metadata, objects and image tags | Yes | No
| Administrative functions (user management) | N/A | Yes

## Background

Primarily what I want Immich to do is to backup all my photos from both my mobile phone, and my wife's phone, so that we can have a consolidated photo backup for our family. (*We currently use a dedicated gmail account with Google Photos for this purpose, but it's run out of space and is a little convoluted*)

We're iOS users, and we have a 2TB family iCloud account to which all of our photos are synced. Since the advent of iCloud Photo Library, it's not possible to "combine" photo libraries, so the only way we can share photos of our family is to manually add them to an album which one of us shares with the other. This is waaay too much work, and what inevitably happens is that we each end up with separate photo albums, and regularly have to send each other photos of events and kids.

So what I'm looking for is a solution to replace Google Photos - a way for each user to upload *all* photos taken on their device, and have these photos combined into a "master album" which both parties can access, manage, and create albums from.

## Details

### Install

I've written a recipe to [install Immich in Docker Swarm][immich]. Immich can also be "automatically" installed using the ansible playbook in [Premix](/premix/) 🚀.

### Web UI

The setup process was straightforward. After deploying Immich, I was prompted to setup a username and password, which subsequently became my admin credentials. Using these credentials, I setup a second user, and shared an album with him. Here's a video I made to illustrate the process:

<iframe width="560" height="315" src="https://www.youtube.com/embed/L1V_P2NRhlE" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Mobile app

The Mobile app seems very polished, and based on my testing, works better than the Synology "Moments" app I was previously trialling (*especially given the volume of photos I have!*)

<figure markdown>
  ![Immich Screenshot](/images/reviews/immich-mobile.gif){ loading=lazy }
  <figcaption>Apparently this was 4000+ photos!</figcaption>
</figure>

### Other

Here's what the filesystem where photos are stored looks like:

```bash
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/34ce58c4-8100-49d4-a5a3-f13a74b478f9.webp
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/34ce58c4-8100-49d4-a5a3-f13a74b478f9.jpeg
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/7d8abe14-77c3-4214-804a-d35d68084a2c.webp
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/309228ef-0b21-4986-acc4-d0c0d10e43ac.webp
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/309228ef-0b21-4986-acc4-d0c0d10e43ac.jpeg
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/7d8abe14-77c3-4214-804a-d35d68084a2c.jpeg
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/8adff3fe-d0ac-4855-b0ca-12a1f6ef2caf.webp
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/8adff3fe-d0ac-4855-b0ca-12a1f6ef2caf.jpeg
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/30505706-520b-4eac-89ed-9f1227802306.jpeg
/var/data/immich/upload/49a82212-e1bb-48d9-8b8f-7076e54bd6aa/thumb/WEB/30505706-520b-4eac-89ed-9f1227802306.webp
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/original
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/original/WEB
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/original/WEB/2245d33b-fbc5-40ee-a50b-2a234f73e3d9.jpg
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/thumb
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/thumb/WEB
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/thumb/WEB/2245d33b-fbc5-40ee-a50b-2a234f73e3d9.webp
/var/data/immich/upload/cae22784-474c-4527-825c-46d7f324e8e8/thumb/WEB/2245d33b-fbc5-40ee-a50b-2a234f73e3d9.jpeg
```

As you'll note, while it's true that files are stored locally, there's no filesystem-level metadata easily parsable, like yearly or album-based folders. While the files are stored locally, and *technically* you could move them elsewhere, it certainly wouldn't be easy.

It's also not easy to access the files via any sort of sharing (*NFS, SMB, etc*), other than using the Immich UI. Par for the course though, I expect, if we want to be able to rely on the database for metadata without requiring intensive filesystem interaction.

## Alternatives

### Photoprism

Until Immich, the only viable self-hosted Google Photos replacement I was aware of was [Photoprism][photoprism], which has a far wider featureset and several years of stable releases.

Given my goal of having a non-Apple secondary backup of my family photos, let's selfishly compare the features which matter (*to me*):

<figure markdown>
| Feature | Immich      | Photoprism |
| ----- | ----------- | ------------------------------------ |
| :material-nas: Photos stored locally | Y | Y |
| :octicons-device-mobile-24: Automatic mobile uploads (automatic) | Y  | [paid 3rd-party app](https://www.photosync-app.com/home.html) |
| :material-share-variant: Share albums with trusted users | Y  | Y |
| :material-bomb-off: Stable release | haha | [2021](https://docs.photoprism.app/developer-guide/)
| :material-face-recognition: AI facial recognition | N | Y |
| :octicons-tag-24: AI tagging ("photo of dog") | Y | Y |

  <figcaption>Immich vs Photoprism</figcaption>
</figure>

Conclusion: For my secondary-backup use-case, Immich (*even in its current pre-production buggy state*) is perfectly fine. The mobile app is beautiful (*if a little buggy*), and I do appreciate the cheeky "Google Photos" theming / styling. I think it'll appeal to a lot of Google Photos refugees for this reason alone.

### Google Photos

OK, obviously one is self-hosted, and the other is not. This massive difference aside, again for my use-case, the other feature differences are:

<figure markdown>
| Feature | Immich      | Google Photos |
| ----- | ----------- | ------------------------------------ |
| :material-nas: Storage limit | :octicons-infinity-24: | 15GB :fontawesome-solid-hand-middle-finger: |
| :octicons-device-mobile-24: Automatic mobile uploads (automatic) | Y | Y (*but deletions sync with my phone, which is less-than-idea, for my secondary-backup plan*) |
| :material-share-variant: Share all photos with user | Y | Only with 1 partner :couple:  |
| :material-bomb-off: Stable release | haha | Y
| :material-face-recognition: AI facial recognition | N | Y |
| :octicons-tag-24: AI tagging ("photo of dog") | Y | Y |

  <figcaption>Immich vs Google Photos</figcaption>
</figure>

**Conclusion**: I setup my secondary-backup plan when Google first announced unlimited storage for Google Photos. Now that this is no longer possible, I'm out.

## Summary

### TL;DR

I'm in (*for a secondary backup to my iCloud Photo Library*)

Based on how the pre-production development has progressed, and the massive hunger in the self-hosted community for an alternative to Google Photos, I suspect that Immich will quickly gain traction and continue its rapid pace of development.

Please [join me](/#sponsored-projects) in sponsoring [@alextran1502](https://github.com/sponsors/alextran1502), to support this exceptional product!

--8<-- "review-footer.md"

[^1]: "wife-insurance": When the developer's wife is a primary user of the platform, you can bet he'll be writing quality code! :woman: :material-karate: :man: :bed: :cry:
[^2]: There's a [friendly Discord server](https://discord.com/invite/D8JsnBEuKb) for Immich too!
