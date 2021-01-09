---
name: "\U0001F370 Request a recipe!"
about: "I have a request for a fresh recipe \U0001F60B"
title: "[recipe request] "
labels: recipe/new
assignees: funkypenguin

---

## Recipe Request

** Briefly describe the new recipe you'd like added **

### Prerequisites

Let's talk about must-haves. If you don't know the answer to the following, then go no further until you do!

* [ ] I have searched and confirmed no existing open or closed issues/PRs for this app
* [ ] The app is actively supported by its developers (_i.e., not deprecated_)

### Basic details

Add as many of the details below as possible - this'll help to determine the structure of the recipe:

* [ ] Project homepage:
* [ ] Docker image:
* [ ] Subreddit (optional):
* [ ] Docker-compose file (optional):
* [ ] Kubernetes helm chart (optional): 

### Screenshot

<!-- Paste in a single, beautiful screenshot, which should be included in the recipe -->

### Access Control 

Does the app provide its own authentication (_i.e. NextCloud_), or does it require an authentication frontend (_i.e., Radarr_)?

How should access to the app be managed?

* [ ] The app provides its own, trustworthy authentication, or access control is unnecessary. I'd be happy exposing it to the internet
* [ ] The app needs something in front of it to secure access (_traefik-forward-auth, authelia, etc_)

<!-- Add any extra details necessary to explain the selections above -->

### Config Management

How is the app configured? Some applications are configured [entirely using environment variables](https://12factor.net), some need static config files mounted into their container, and some are configured using an interactive setup process (_i.e. NextCloud_). 

* [ ] Environment variables
* [ ] Static config file
* [ ] Interactive setup which then persists the config somewhere to the filesystem

<!-- Add any extra details necessary to explain the selections above -->

### Connectivity

What sort of network connectivity does the app need?

* [ ] None
* [ ] Requires inbound web access HTTP/S access
* [ ] Requires inbound arbitrary TCP/UDP access
* [ ] Requires connectivity to other apps

<!-- Add any extra details necessary to explain the selections above -->

### Data Management

What sort of persisted data does the app need?

* [ ] The app needs access to its own persistent data (i.e. logs, database directory, etc)
* [ ] The app needs access to outside data (i.e. Plex)
* [ ] The app needs access to *another* app's data

<!-- Add any extra details necessary to explain the selections above -->

### Backup

How is backup of the app's data to be handled?

* [ ] Backup is unnecessary
* [ ] A simple file-based copy of the app's data folders will suffice
* [ ] A process is required to create backups for a file-based copy (i.e., a mysql database dump)
* [ ] A custom backup/restore process is required (provide details below)

<!-- Add any extra details necessary to explain the selections above -->

### Platform

Which platform(s) are you interested in a recipe supporting?
* [ ] Docker Swarm (_via docker-compose files_)
* [ ] Docker Swarm (_via premix ansible deploy_)
* [ ] Kubernetes (_via a helm chart_)


### Level of engagement

I'm willing to:

* [ ] Submit a PR for the recipe
* [ ] Test the recipe
* [ ] Engage the community on Q&A for the recipe
