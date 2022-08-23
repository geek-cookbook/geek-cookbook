---
title: Pre-made ansible playbooks to deploy our self-hosted recipes
---
# Premix Repository

"Premix" is a private repository shared with [GitHub sponsors](https://github.com/sponsors/funkypenguin), which contains the necessary files and automation to quickly deploy any recipe, or even an entire [swarm](/docker-swarm/) / [cluster](/kubernetes/)! :muscle:

![Screenshot of premix repo](/images/premix.png){ loading=lazy }

## Benefits

### 🎁 Early access

Recipes are usually "baked" in premix first, before they are published on the website. Having access to premix means having access to all the freshest recipes!

### ⛳️ Eliminate toil

Building hosts, installing OS and deploying tooling is all "prep" for the really fun stuff - deploying and using recipes!

Premix [eliminates  TOIL](https://sre.google/sre-book/eliminating-toil/) with an ansible playbook to deploy a fresh cluster automatically, or apply individual recipes to an existing cluster.

(*You still have to "feed" the playbook your configuration, but it's centralized, repeatable, and versionable*.)

### 🏔 Proven stability

The ansible playbook used to deploy clusters is also used to validate all PRs in CI, giving assurance that new recipes and changes introduced will work alongside existing ones. Additionally, the CI swarm/cluster is routinely rebuilt "from scratch" to validate the playbook end-to-end.

### 📈 Ongoing updates

Typically you'd fork the repository to overlay your own config and changes. As more recipes are added to premix, incorporating these into your repo is a simple git merge operation, which can be automated or manually triggered.

## How to get Premix

To get invited to the premix repo, follow these steps:

1. Become a **public** [sponsor](https://github.com/sponsors/funkypenguin) on GitHub
2. Join us in the [Discord server](http://chat.funkypenguin.co.nz)
3. Link your accounts at [PenguinPatrol](https://penguinpatrol.funkypenguin.co.nz)
4. Say something in any of the discord channels (*this triggers the bot*)

You'll receive an invite to premix to the email address associated with your GitHub account, and a fancy VIP role in the Discord server! 💪

!!! question "Why require public sponsorship?"
    Public sponsorship is required for the bot to realize that you're a sponsor, based on what the GitHub API provides

### Without a credit card

Got no credit card / GitHubz? We got you covered, with this nifty [PayPal-based subscription](https://www.paypal.com/webapps/billing/plans/subscribe?plan_id=P-95D29301K5084144PMKCWFEY)
