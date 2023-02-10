---
date: 2022-09-01
categories:
  - note
tags:
  - minio
title: How to run Minio in legacy FS mode again
description: Has your bare-metal / single-node Minio deployment started creating .xl.meta files instead of the files you actually intended to transfer? This is happening because of a significant update / deprecation in June 2022
---

# How to run Minio in legacy FS mode again

Has your bare-metal / single-node Minio deployment started creating `.xl.meta` files instead of the files you actually intended to transfer? This is happening because of a significant update / deprecation in June 2022.

Here's a workaround to restore the previous behaviour..

<!-- more -->

## Background

Starting with [RELEASE.2022-06-02T02-11-04Z](https://github.com/minio/minio/releases/tag/RELEASE.2022-06-02T02-11-04Z), MinIO implements a zero-parity erasure coded backend for single-node single-drive deployments. This feature allows access to [erasure coding dependent features](https://min.io/docs/minio/linux/operations/concepts/erasure-coding.html?ref=docs-redirect#minio-erasure-coding) without the requirement of multiple drives..

## .xl.meta instead of files

This unfortunately breaks expected behavior for a large number of existing users, since Minio can no longer be used to provide an S3-compatible layer to transfer files to later be consumed via typical POSIX access.

## Workaround to revert Minio to legacy fs mode

Note that the [docs re pre-existing data](https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html?ref=docs-redirect#pre-existing-data) indicate that in the case of Existing filesystem folders, files, and MinIO backend data, then MinIO resumes in the legacy filesystem (“Standalone”) mode with no erasure-coding features.

So a simple workaround is to create the following format.json in `/path-to-existing-data/.minio.sys/`:

```json
{"version":"1","format":"fs","id":"avoid-going-into-snsd-mode-legacy-is-fine-with-me","fs":{"version":"2"}}
```

When Minio starts, it recognizes this as "existing" (above), and happily starts in legacy mode! 👍🏻

## Summary

The lifespan of Minio's FS overlay mode is limited. The solution presented provides a temporary solution to continue using FS mode, but ultimately Minio are intent on removing this feature[^1].

[^1]: As it turns out, `RELEASE.2022-10-24T18-35-07Z` was the last version to work with overlay mode at all. If you want to continue using Minio the way you've used for years, you'll want to stay on this version.

--8<-- "blog-footer.md"
