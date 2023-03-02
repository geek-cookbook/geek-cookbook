---
date: 2023-03-03
categories:
  - note
tags:
  - helm
title: When helm says "no" (failed to delete release)
description: TIL that a helm chart which used deprecated APIs can't be upgraded/removed after a major Kubernetes version upgrade, without a little "help"
---

# When helm says "no" (failed to delete release)

My beloved "[Penguin Patrol](https://penguinpatrol.funkypenguin.co.nz)" bot, which I use to give [GitHub][github_sponsor] / [Patreon][patreon] / [Ko-Fi][kofi] supporters access to the [premix](/premix/) repo, was deployed on a Kube 1.19 [Digital Ocean](/kubernetes/cluster/digitalocean/) cluster, 3 years ago. At the time, the Ingress API was at v1beta1.

Fast-forward to today, and several Kubernetes major version upgrades later (*it's on 1.23 currently, and we're on Ingress v1*), and I discovered that I was unable to upgrade the chart, since helm complained that the **previous** release referred to deprecated APIs.

Worse, helm wouldn't let me **delete** and re-install the release - because of those damned deprecated APIs!

Here's how I fixed it...

<!-- more -->

## Use the helm mapkubeapis plugin

I stumbled across [this helpful comment](https://github.com/helm/helm/issues/11513#issuecomment-1404101041), which gave me the solution.

I installed the [mapkubeapis](https://github.com/helm/helm-mapkubeapis) helm plugin using ` helm plugin install https://github.com/helm/helm-mapkubeapis`

```bash
~❯ helm plugin install https://github.com/helm/helm-mapkubeapis                                                 
Downloading and installing helm-mapkubeapis v0.3.2 ...
https://github.com/helm/helm-mapkubeapis/releases/download/v0.3.2/helm-mapkubeapis_0.3.2_darwin_amd64.tar.gz
Installed plugin: mapkubeapis
~❯
```

Then I ran mapkubeapis against my crusty ol' helm release:

```bash
~❯ helm mapkubeapis -n penguinpatrol penguinpatrol                                                          
2023/03/03 10:45:13 Release 'penguinpatrol' will be checked for deprecated or removed Kubernetes APIs and will be updated if necessary to supported API versions.
2023/03/03 10:45:13 Get release 'penguinpatrol' latest version.
2023/03/03 10:45:15 Check release 'penguinpatrol' for deprecated or removed APIs...
2023/03/03 10:45:16 Found 1 instances of deprecated or removed Kubernetes API:
"apiVersion: networking.k8s.io/v1beta1
kind: Ingress
"
Supported API equivalent:
"apiVersion: networking.k8s.io/v1
kind: Ingress
"
2023/03/03 10:45:16 Finished checking release 'penguinpatrol' for deprecated or removed APIs.
2023/03/03 10:45:16 Deprecated or removed APIs exist, updating release: penguinpatrol.
2023/03/03 10:45:16 Set status of release version 'penguinpatrol.v39' to 'superseded'.
2023/03/03 10:45:16 Release version 'penguinpatrol.v39' updated successfully.
2023/03/03 10:45:16 Add release version 'penguinpatrol.v40' with updated supported APIs.
2023/03/03 10:45:16 Release version 'penguinpatrol.v40' added successfully.
2023/03/03 10:45:16 Release 'penguinpatrol' with deprecated or removed APIs updated successfully to new version.
2023/03/03 10:45:16 Map of release 'penguinpatrol' deprecated or removed APIs to supported versions, completed successfully.
~❯
```

And I was finally able to delete the "stuck" release, with a `helm delete`[^1]!

## Summary

What did I learn?

1. Upgrade your deprecated APIs **before** upgrading your Kubernetes major versions
2. `helm ls -a` can help identify stuck releases which wouldn't normally appear with a simple `helm ls`

[^1]: And now the misbehaving chart can be re-installed, since there's no invalid **previous** version to worry about!

--8<-- "common-links.md"
--8<-- "blog-footer.md"
