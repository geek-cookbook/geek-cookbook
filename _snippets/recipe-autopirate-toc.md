## Assemble more tools..

Continue through the list of tools below, adding whichever tools your want to use, and finishing with the **[end](/recipes/autopirate/end/)** section:

* [Headphones](/recipes/autopirate/headphones/)
* [Heimdall](/recipes/autopirate/heimdall/)
* [Jackett](/recipes/autopirate/jackett/)
* [Lazy Librarian](/recipes/autopirate/lazylibrarian/)
* [Lidarr](/recipes/autopirate/lidarr/)
* [Mylar](/recipes/autopirate/mylar/)
* [NZBGet](/recipes/autopirate/nzbget.md)
* [NZBHydra](/recipes/autopirate/nzbhydra/)
* [Ombi](/recipes/autopirate/ombi/)
* [Radarr](/recipes/autopirate/radarr/)
* [RTorrent](/recipes/autopirate/rtorrent/)
* [SABnzbd](/recipes/autopirate/sabnzbd.md)
* [Sonarr](/recipes/autopirate/sonarr/)
* [End](/recipes/autopirate/end/) (launch the stack)

[^1]: In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.