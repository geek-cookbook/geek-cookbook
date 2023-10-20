---
title: Support CSI VolumeSnapshots with snapshot-controller
description: Add CSI VolumeSnapshot support with snapshot support
values_yaml_url: https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/values.yaml
helm_chart_version: 5.1.x
helm_chart_name: velero
helm_chart_repo_name: vmware-tanzu
helm_chart_repo_url: https://vmware-tanzu.github.io/helm-charts
helmrelease_name: velero
helmrelease_namespace: velero
kustomization_name: velero
slug: Velero
status: new
---

# Velero

Don't be like [Cameron](http://haltandcatchfire.wikia.com/wiki/Cameron_Howe). Backup your stuff.

<!-- markdownlint-disable MD033 -->
<iframe width="560" height="315" src="https://www.youtube.com/embed/1UtFeMoqVHQ" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

[Velero](https://velero.io/), a VMWare-backed open-source project, is a mature cloud-native backup solution, able to selectively backup / restore your various workloads / data.

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) 
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped

    Optional:

    * [ ] S3-based storage for off-cluster backup

    Optionally for volume snapshot support:
    
    * [ ] Persistence supporting PVC snapshots for in-cluster backup (*i.e., [Rook Ceph](/kubernetes/persistence/rook-ceph/)*)
    * [ ] [Snapshot controller](/kubernetes/backup/csi-snapshots/snapshot-controller/) with [validation webhook](/kubernetes/backup/csi-snapshots/snapshot-validation-webhook/)
  
## Terminology

Let's get some terminology out of the way. Velero manages [Backups](https://velero.io/docs/main/api-types/backup/) and [Restores](https://velero.io/docs/main/api-types/restore/), to [BackupStorageLocations](https://velero.io/docs/main/api-types/backupstoragelocation/), and optionally snapshots volumes to [VolumeSnapshotLocations](https://velero.io/docs/main/api-types/volumesnapshotlocation/), either manually or on a [Schedule](https://velero.io/docs/main/api-types/schedule/).

Clear as mud? :footprints:

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}

### SealedSecret

We'll need credentials to be able to access our S3 storage, so let's create them now. Velero will use AWS credentials in the standard format preferred by the AWS SDK, so create a temporary file like this:

```bash title="mysecret.aws.is.dumb"
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_OR_S3_COMPATIBLE_EQUIVALENT
aws_secret_access_key = YOUR_AWS_SECRET_KEY_OR_S3_COMPATIBLE_EQUIVALENT
```

And then turn this file into a secret, and seal it, with:

```bash
kubectl create secret generic -n velero velero-credentials \
  --from-file=cloud=mysecret.aws.is.dumb \
  -o yaml --dry-run=client \
  | kubeseal > velero/sealedsecret-velero-credentials.yaml
```

You can now delete `mysecret.aws.is.dumb` :thumbsup:

{% include 'kubernetes-flux-helmrelease.md' %}

## Configure Velero

Here are some areas of the upstream values.yaml to pay attention to..

### initContainers 

Uncomment `velero-plugin-for-aws` to use an S3 target for backup, and additionally uncomment `velero-plugin-for-csi` if you plan to create volume snapshots:

```yaml
    # Init containers to add to the Velero deployment's pod spec. At least one plugin provider image is required.
    # If the value is a string then it is evaluated as a template.
    initContainers:
      - name: velero-plugin-for-csi
        image: velero/velero-plugin-for-csi:v0.6.0
        imagePullPolicy: IfNotPresent
        volumeMounts:
          - mountPath: /target
            name: plugins
      - name: velero-plugin-for-aws
        image: velero/velero-plugin-for-aws:v1.8.0
        imagePullPolicy: IfNotPresent
        volumeMounts:
          - mountPath: /target
            name: plugins
```

### backupStorageLocation

Additionally, it's required to configure certain values (*highlighted below*) under the `configuration` key:

```yaml hl_lines="7 9 11 25 27 31 33"
    configuration:
      # Parameters for the BackupStorageLocation(s). Configure multiple by adding other element(s) to the backupStorageLocation slice.
      # See https://velero.io/docs/v1.6/api-types/backupstoragelocation/
      backupStorageLocation:
        # name is the name of the backup storage location where backups should be stored. If a name is not provided,
        # a backup storage location will be created with the name "default". Optional.
      - name: 
        # provider is the name for the backup storage location provider.
        provider: aws # if we're using S3-compatible storage (1)
        # bucket is the name of the bucket to store backups in. Required.
        bucket: my-awesome-bucket # the name of my specific bucket (2)
        # caCert defines a base64 encoded CA bundle to use when verifying TLS connections to the provider. Optional.
        caCert:
        # prefix is the directory under which all Velero data should be stored within the bucket. Optional.
        prefix: optional-subdir # a path under the bucket in which the backup data should be stored (3)
        # default indicates this location is the default backup storage location. Optional.
        default: true # prevents annoying warnings in the log
        # validationFrequency defines how frequently Velero should validate the object storage. Optional.
        validationFrequency:
        # accessMode determines if velero can write to this backup storage location. Optional.
        # default to ReadWrite, ReadOnly is used during migrations and restores.
        accessMode: ReadWrite
        credential:
          # name of the secret used by this backupStorageLocation.
          name: velero-credentials # this is the sealed-secret we created above (3)
          # name of key that contains the secret data to be used.
          key: cloud # this is the key we used in the sealed-secret we created above (3)
        # Additional provider-specific configuration. See link above
        # for details of required/optional fields for your provider.
        config:
         region: # set-this-to-your-b2-region, for example us-west-002
         s3ForcePathStyle:
         s3Url: # set this to the https URL to your endpoint, for example "https://s3.us-west-002.backblazeb2.com"
        #  kmsKeyId:
        #  resourceGroup:
        #  The ID of the subscription containing the storage account, if different from the cluster’s subscription. (Azure only)
        #  subscriptionId:
        #  storageAccount:
        #  publicUrl:
        #  Name of the GCP service account to use for this backup storage location. Specify the
        #  service account here if you want to use workload identity instead of providing the key file.(GCP only)
        #  serviceAccount:
        #  Option to skip certificate validation or not if insecureSkipTLSVerify is set to be true, the client side should set the
        #  flag. For Velero client Command like velero backup describe, velero backup logs needs to add the flag --insecure-skip-tls-verify
        #  insecureSkipTLSVerify:
```

1. There are other providers
2. Your bucket name, unique to your S3 provider
3. I use prefixes to backup multiple clusters to the same bucket

### volumeSnapshotLocation

Also under the `config` key, you'll find the `volumeSnapshotLocation` section. Use this if you're using a [supported provider](https://velero.io/docs/v1.6/supported-providers/), and you want to create in-cluster snapshots. In the following example, I'm creating Velero snapshots with rook-ceph using the CSI provider. Take note of the highlighted sections, these are the minimal options you'll want to set:

```yaml hl_lines="3 6 40 65"
      volumeSnapshotLocation:
        # name is the name of the volume snapshot location where snapshots are being taken. Required.
      - name: rook-ceph
        # provider is the name for the volume snapshot provider. If omitted
        # `configuration.provider` will be used instead.
        provider: csi
        # Additional provider-specific configuration. See link above
        # for details of required/optional fields for your provider.
        config: {}
      #    region:
      #    apiTimeout:
      #    resourceGroup:
      #    The ID of the subscription where volume snapshots should be stored, if different from the cluster’s subscription. If specified, also requires `configuration.volumeSnapshotLocation.config.resourceGroup`to be set. (Azure only)
      #    subscriptionId:
      #    incremental:
      #    snapshotLocation:
      #    project:
      # These are server-level settings passed as CLI flags to the `velero server` command. Velero
      # uses default values if they're not passed in, so they only need to be explicitly specified
      # here if using a non-default value. The `velero server` default values are shown in the
      # comments below.
      # --------------------
      # `velero server` default: restic
      uploaderType:
      # `velero server` default: 1m
      backupSyncPeriod:
      # `velero server` default: 4h
      fsBackupTimeout:
      # `velero server` default: 30
      clientBurst:
      # `velero server` default: 500
      clientPageSize:
      # `velero server` default: 20.0
      clientQPS:
      # Name of the default backup storage location. Default: default
      defaultBackupStorageLocation:
      # How long to wait by default before backups can be garbage collected. Default: 72h
      defaultBackupTTL:
      # Name of the default volume snapshot location.
      defaultVolumeSnapshotLocations: csi:rook-ceph
      # `velero server` default: empty
      disableControllers:
      # `velero server` default: 1h
      garbageCollectionFrequency:
      # Set log-format for Velero pod. Default: text. Other option: json.
      logFormat:
      # Set log-level for Velero pod. Default: info. Other options: debug, warning, error, fatal, panic.
      logLevel:
      # The address to expose prometheus metrics. Default: :8085
      metricsAddress:
      # Directory containing Velero plugins. Default: /plugins
      pluginDir:
      # The address to expose the pprof profiler. Default: localhost:6060
      profilerAddress:
      # `velero server` default: false
      restoreOnlyMode:
      # `velero server` default: customresourcedefinitions,namespaces,storageclasses,volumesnapshotclass.snapshot.storage.k8s.io,volumesnapshotcontents.snapshot.storage.k8s.io,volumesnapshots.snapshot.storage.k8s.io,persistentvolumes,persistentvolumeclaims,secrets,configmaps,serviceaccounts,limitranges,pods,replicasets.apps,clusterclasses.cluster.x-k8s.io,clusters.cluster.x-k8s.io,clusterresourcesets.addons.cluster.x-k8s.io
      restoreResourcePriorities:
      # `velero server` default: 1m
      storeValidationFrequency:
      # How long to wait on persistent volumes and namespaces to terminate during a restore before timing out. Default: 10m
      terminatingResourceTimeout:
      # Comma separated list of velero feature flags. default: empty
      # features: EnableCSI
      features: EnableCSI
      # `velero server` default: velero
      namespace:      
```

### schedules

Set up backup schedule(s) for your preferred coverage, TTL, etc. See [Schedule](https://velero.io/docs/main/api-types/schedule/) for a list of available configuration options under the `template` key:

```yaml
    schedules:
      daily-backups-r-cool:
        disabled: false
        labels:
          myenv: foo
        annotations:
          myenv: foo
        schedule: "0 0 * * *" # once a day, at midnight
        useOwnerReferencesInBackup: false
        template:
          ttl: "240h"
          storageLocation: default # use the same name you defined above in backupStorageLocation
          includedNamespaces:
          - foo
```

{% include 'kubernetes-flux-check.md' %}

### Is it working?

Confirm that the basic config is good, by running `kubectl logs -n velero -l app.kubernetes.io/name=velero`:

```bash
time="2023-10-17T22:24:40Z" level=info msg="Validating BackupStorageLocation" backup-storage-location=velero/b2 controller=backup-storage-location logSource="pkg/controller/backup_storage_location_controller.go:152"
time="2023-10-17T22:24:41Z" level=info msg="BackupStorageLocations is valid, marking as available" backup-storage-location=velero/b2 controller=backup-storage-location logSource="pkg/controller/backup_storage_location_controller.go:137"
```

!!! tip "Confirm Velero is happy with your BackupStorageLocation"
    The pod output will tell you if Velero is unable to access your BackupStorageLocation. If this happens, the most likely cause will be a misconfiguration of your S3 settings!

### Test backup

Next, you'll need the Velero CLI, which you can install on your OS based on the instructions [here](https://velero.io/docs/v1.12/basic-install/#install-the-cli)

Create a "quickie" backup of a namespace you can afford to loose, like this:

```bash
velero backup create goandbeflameretardant --include-namespaces=chartmuseum --wait
```

Confirm your backup completed successfully, with:

```bash
velero backup describe goandbeflameretardant
```

Then, like a boss, **delete** the original namespace (*you can afford to loose it, right?*) with some bad-ass command like `kubectl delete ns chartmuseum`. Now it's gone.

### Test restore

Finally, in a kick-ass move of ninja :ninja: sysadmin awesomeness, restore your backup with:

```bash
velero create restore --from-backup goandbeflameretardant --wait
```

Confirm that your pods / data have been restored.

Congratulations, you have a backup!

### Test scheduled backup

Confirm the basics are working by running `velero get schedules`, to list your schedules:

```bash
davidy@gollum01:~$ velero get schedules
NAME           STATUS    CREATED                         SCHEDULE    BACKUP TTL   LAST BACKUP   SELECTOR   PAUSED
velero-daily   Enabled   2023-10-13 04:20:42 +0000 UTC   0 0 * * *   240h0m0s     22h ago       <none>     false
davidy@gollum01:~$
```

Force an immediate backup per che schedule, by running `velero backup create --from-schedule=velero-daily`:

```bash
davidy@gollum01:~$ velero backup create --from-schedule=velero-daily
Creating backup from schedule, all other filters are ignored.
Backup request "velero-daily-20231017222207" submitted successfully.
Run `velero backup describe velero-daily-20231017222207` or `velero backup logs velero-daily-20231017222207` for more details.
davidy@gollum01:~$
```

Use the `describe` and `logs` command outputted above to check the state of your backup (*you'll only get the backup logs after the backup has completed*)

When describing your completed backup, if the result is anything but a complete success, then further investigation is required.

## Summary

What have we achieved? We've got scheduled backups running, and we've successfully tested a restore!

!!! summary "Summary"
    Created:

    * [X] Velero running and creating restorable backups on schedule


[^1]: This is where you'd add multiple Volume Groups if you wanted a storageclass per Volume Group
