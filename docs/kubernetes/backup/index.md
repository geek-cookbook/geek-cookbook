# Backup

> Waitasec, what happened to "cattle :cow:, not pets"? Why should you need backup in your cluster?

Ha. good question. If you're happily running Kubernetes in a cloud provider and using managed services for all your stateful workloads (*managed databases, etc*) then you don't need backup.

If, on the other hand, you're actually **using** the [persistence](/kubernetes/persistence/) you deployed earlier, presumably some of what you persist is important to you, and you'd want to back it up in the event of a disaster (*or you need to roll back a database upgrade!*).

The only backup solution I've put in place thus far is Velero, but this index page will be expanded to more options as they become available.

For your backup needs, I present, Velero, by VMWare:

* [Velero](/kubernetes/backup/velero/)

--8<-- "recipe-footer.md"
