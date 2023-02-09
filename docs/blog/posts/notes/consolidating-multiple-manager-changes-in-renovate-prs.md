---
date: 2023-02-07
categories:
  - note
tags:
  - renovate
title: How to consolidating multiple manager changes in Renovate PRs
description: Here's how to configure Renovate to only create 1 PR per-file, even if multiple changes are required
---

# Consolidating multiple manager changes in Renovate PRs

I work on several large clusters, administered using [FluxCD](/kubernetes/deployment/flux/), which in which we carefully manage the update of Helm releases using Flux's `HelmRelease` CR.

Recently, we've started using [Renovate](https://github.com/renovatebot/renovate) to alert us to pending upgrades, by creating PRs when a helm update *or* an image update in the associated helm values.yaml is available (*I like to put the upstream chart's values in to the `HelmRelease` so that changes can be tracked in one place*)

The problem is, it's likely that the images in a chart's `values.yaml` **will** be updated when the chart is updated, but I don't need a separate PR for each image! (*imagine a helm chart with 10 image references!*)

The first time I tried this, I ended up with 98 separate PRs, so I made some changes to Renovate to try to "bundle" associated helmrelease / helm values together...

<!-- more -->

## Create a "bait" HelmRelease

Here's the challenge - given only a helm release version number, how do we create a file containing the helmrelease details, **and** the helm value details? Turns out that's relatively easy, since helm is able to retrieve a chart's values with `helm show values`, so I have an ansible playbook which (*per helm-chart*) retrieves these, using `helm show values {{ helm_chart_repo }}/{{ helm_chart_name }} --version {{ helm_chart_version }}`. [^1]

The values are inserted into a helmrelease YAML file using a template like this:

```yaml
{% raw %}
# This file exists simply to trigger renovatebot to alert us to upstream updates, and it's not
# intended to ever be actually processed by flux
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ helm_chart_release }}
  namespace: {{ helm_chart_namespace }}
spec:
  chart:
    spec:
      chart: {{ helm_chart_name }}
      version: {{ helm_chart_version }}
      sourceRef:
        kind: HelmRepository
        name: {{ helm_chart_repo }}
        namespace: flux-system
  values:
{% filter indent(width=4) %}
{{ _helm_default_values.stdout }}
{% endfilter %}
{% endraw %}
```

Which results in a helmrelease which looks a bit like this:

```yaml
{% raw %}
# This file exists simply to trigger renovatebot to alert us to upstream updates, and it's not
# intended to ever be actually processed by flux
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: mongodb
  namespace: mongodb
spec:
  chart:
    spec:
      chart: mongodb
      version: 13.6.2
      sourceRef:
        kind: HelmRepository
        name: bitnami
        namespace: flux-system
  values:

    ## @section Global parameters
    ## Global Docker image parameters

<snip for readability>

    ## Bitnami MongoDB(&reg;) image
    ## ref: https://hub.docker.com/r/bitnami/mongodb/tags/
    ## @param image.registry MongoDB(&reg;) image registry
    ## @param image.repository MongoDB(&reg;) image registry
    ## @param image.tag MongoDB(&reg;) image tag (immutable tags are recommended)
    ## @param image.digest MongoDB(&reg;) image digest in the way sha256:aa.... Please note this parameter, if set, will override the tag
    ## @param image.pullPolicy MongoDB(&reg;) image pull policy
    ## @param image.pullSecrets Specify docker-registry secret names as an array
    ## @param image.debug Set to true if you would like to see extra information on logs
    ##
    image:
      registry: docker.io
      repository: bitnami/mongodb
      tag: 6.0.3-debian-11-r9
{% endraw %}
```

I save this helmrelease **outside** of my flux-managed folders into a folder called `renovatebait` (*I don't want to actually apply changes immediately, I just want to be told that there are changes available. There will inevitably be some "massaging" of the default values required, but now I know that an update is available.*)

## Alter Renovate's packageFile value

Just pointing renovate at this file would still create multiple PRs, since each renovate "manager" creates its PR branches independently... the secret sauce is changing the **name** of the branch renovate uses for its PRs, like this:

```yaml
{% raw %}
  "flux": {
    "fileMatch": ["renovatebait/.*"]
  },
  "helm-values": {
    "fileMatch": ["renovatebait/.*"]
  },
  "branchTopic": "{{{replace 'helmrelease-' '' packageFile}}}",
{% endraw %}
```

The `branchTopic` value takes the `packageFile` name (i.e., `helmrelease-mongodb.yaml`), strips off the `helmrelease-`, and creates a PR branch named `renovate/renovatebait/mongodb.yaml`.

Now next time renovate runs, I get a single, nice succinct PR with a list of all the chart/images changes, like this:

![PR summary screenshot](/images/blog/multiple-renovate-prs-summary.png)

And an informative diff, like this:

![PR screenshot](/images/blog/multiple-renovate-prs-detail.png)

## Summary

By changing the name of the PR branch that renovate uses to create its PRs, it's possible to consolidate all the affected changes in a single PR. W00t!

[^1]: Yes, we ansiblize the creation of our helmreleases. It means all versions (*images and charts*) can be captured in one ansible dictionary.

--8<-- "blog-footer.md"
