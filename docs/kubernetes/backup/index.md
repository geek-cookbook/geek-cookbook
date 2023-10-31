# Backup

Don't be like [Cameron](http://haltandcatchfire.wikia.com/wiki/Cameron_Howe). Backup your stuff.

<!-- markdownlint-disable MD033 -->
<iframe width="560" height="315" src="https://www.youtube.com/embed/1UtFeMoqVHQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

> Waitasec, what happened to "cattle :cow:, not pets"? Why should you need backup in your cluster?

Ha. good question. If you're happily running Kubernetes in a cloud provider and using managed services for all your stateful workloads (*managed databases, etc*) then you don't need backup.

If, on the other hand, you're actually **using** the [persistence](/kubernetes/persistence/) you deployed earlier, presumably some of what you persist is important to you, and you'd want to back it up in the event of a disaster (*or you need to roll back a database upgrade!*).

The only backup solution I've put in place thus far is Velero, but this index page will be expanded to more options as they become available.

For your backup needs, I present, Velero, by VMWare:

* [Velero](/kubernetes/backup/velero/)

{% include 'recipe-footer.md' %}
