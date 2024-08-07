---
title: Pre-made ansible playbooks to deploy our self-hosted recipes
---
# Premix Repository

"Premix" is a git repository which contains the necessary files and automation to quickly deploy any recipe, or even an entire [swarm](/docker-swarm/) / [cluster](/kubernetes/)! :muscle:

## Benefits

### ⛳️ Eliminate toil

Building hosts, installing OS and deploying tooling is all "prep" for the really fun stuff - deploying and using recipes!

Premix [eliminates  TOIL](https://sre.google/sre-book/eliminating-toil/) with an ansible playbook to deploy a fresh cluster automatically, or apply individual recipes to an existing cluster.

(*You still have to "feed" the playbook your configuration, but it's centralized, repeatable, and versionable*.)

### 🏔 Proven stability

The ansible playbook used to deploy clusters is also used to validate all PRs in CI, giving assurance that new recipes and changes introduced will work alongside existing ones. Additionally, the CI swarm/cluster is routinely rebuilt "from scratch" to validate the playbook end-to-end.

### 📈 Ongoing updates

Typically you'd fork the repository to overlay your own config and changes. As more recipes are added to premix, incorporating these into your repo is a simple git merge operation, which can be automated or manually triggered.

## How to get Premix

Premix used to be sponsors-only (*I'd still love it if you [sponsored](https://github.com/sponsors/funkypenguin)!*), but is now open to all geeks, at https://github.com/geek-cookbook/premix.