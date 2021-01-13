---
name: "\U0001F370 Request a recipe!"
about: "I have a request for a fresh recipe \U0001F60B"
title: "[recipe] "
labels: recipe/request, status/backlog, good first issue
---

<!-- Greetings, fellow geek!

(o_
//\
V_/_   "What's this screwy template?"

The idea here is to _quickly_ create a new recipe request, with a minimum of text entry,
followed by a checklist-driven recipe-preparation process.

"Umm.. what do I do now?"

Fill out the basic section that the penguin points you to, and then save the issue. It'll be
rendered in GitHub's UI, after which go through the checklists and make the necessary adjustments

-->

- [Recipe Request](#recipe-request)
  - [💬 Summary](#-summary)
  - [📝 Instructions](#-instructions)
  - [🖼 Screenshot](#-screenshot)
- [Checklist](#checklist)
  - [☑️ Prerequisites](#️-prerequisites)
  - [👮‍♂️ Access Control](#️-access-control)
  - [⚙️ Config Management](#️-config-management)
  - [🪠 Connectivity](#-connectivity)
  - [💾 Data Management](#-data-management)
  - [🪂 Backup](#-backup)
  - [🤹‍♀️ Orchestration Platform](#️-orchestration-platform)
  - [💍 Engagement](#-engagement)
- [What's next?](#whats-next)
  
# Recipe Request

## 💬 Summary

<!-- 

(o_
//\
V_/_   "Briefly describe the new recipe you'd like added"

-->

* Description: <!-- replace with 1-2 line description of the project -->
* Project homepage: <!-- replace with URL to the project home page -->
* Docker image: <!-- replace with link to the preferred docker container -->
* Community (optional): <!-- replace a link to the project's community or subreddit, 
                             if appropriate. If not, delete this line -->

## 📝 Instructions

<!-- 

(o_
//\
V_/_   "Most projects include instructions on how to deploy via Docker. 
        Include a link to the relevant documentation below, as well as 
        the actual instructions / docker-compose file" 
        
-->

```
< upstream docker compose / install instructions go here >
```

## 🖼 Screenshot

<!-- 

(o_
//\
V_/_    "Paste in a single, beautiful screenshot, which should be included in the recipe"



*** 
That's it for the text entry. Save the issue and then use the much-nicer rich viewer to complete the checklist below.
***

-->

# Checklist

## ☑️ Prerequisites

First, some house-keeping. Review closed issues and PRs, and confirm that this recipe hasn't already been proposed, deprecated, or duplicated before. Also confirm that the application itself is not abandoned.

* [ ] I have searched and confirmed no existing open or closed issues/PRs for this app
* [ ] The app is actively supported by its developers (_i.e., not deprecated_)


## 👮‍♂️ Access Control 

Does the app provide its own authentication (_i.e. NextCloud_), or does it require an authentication frontend (_i.e., Radarr_)?

How should access to the app be managed?

* [ ] The app provides its own, trustworthy authentication, or access control is unnecessary. (*I'd be happy exposing it to the internet*)
* [ ] The app needs something in front of it to secure access (_traefik-forward-auth, authelia, etc_)

<!-- Add any extra details necessary to explain the selections above -->

## ⚙️ Config Management

How is the app configured? Some applications are configured [entirely using environment variables](https://12factor.net), some need static config files mounted into their container, and some are configured using an interactive setup process (_i.e. NextCloud_). 

* [ ] Environment variables
* [ ] Command-line options
* [ ] Static config file
* [ ] Interactive setup which then persists the config somewhere to the filesystem

<!-- Add any extra details necessary to explain the selections above -->

## 🪠 Connectivity

What sort of network connectivity does the app need?

* [ ] None
* [ ] Requires inbound web access HTTP/S access
* [ ] Requires inbound arbitrary TCP/UDP access
* [ ] Requires connectivity to other apps

<!-- Add any extra details necessary to explain the selections above -->

## 💾 Data Management

What sort of persisted data does the app need?

* [ ] The app needs access to its own persistent data (i.e. logs, database directory, etc)
* [ ] The app needs access to outside data (i.e. Plex)
* [ ] The app needs access to *another* app's data

<!-- Add any extra details necessary to explain the selections above -->

## 🪂 Backup

How is backup of the app's data to be handled?

* [ ] Backup is unnecessary
* [ ] A simple file-based copy of the app's data folders will suffice
* [ ] A process is required to create backups for a file-based copy (i.e., a mysql database dump)
* [ ] A custom backup/restore process is required (provide details below)

<!-- Add any extra details necessary to explain the selections above -->

## 🤹‍♀️ Orchestration Platform

Which platform(s) are you interested in a recipe supporting?

* [ ] Docker Swarm (_via docker-compose files_)
* [ ] Docker Swarm (_via premix ansible deploy_)
* [ ] Kubernetes (_via a helm chart_)

## 💍 Engagement

I'm willing to:

* [ ] Submit a PR for the recipe
* [ ] Test the recipe
* [ ] Engage the community on Q&A for the recipe

# What's next?

What happens next? 🙋‍♂️

Seek buy-in from the [community](http://chat.funkypenguin.co.nz), to indicate whether the recipe is a good fit for the cookbook or not.
