---
title: How to deploy Polaris on Kubernetes
description: Deploy Polaris on Kubernetes to audit your safety, security, and resiliency
values_yaml_url: https://github.com/FairwindsOps/charts/blob/master/stable/polaris/values.yaml
helm_chart_version: 5.16.x
helm_chart_name: polaris
helm_chart_repo_name: fairwinds-stable
helm_chart_repo_url: https://charts.fairwinds.com/stable
helmrelease_name: polaris
helmrelease_namespace: polaris
kustomization_name: polaris
slug: polaris
status: new
upstream: https://www.fairwinds.com/polaris
links:
- name: GitHub Repo
  uri: https://github.com/FairwindsOps/polaris
---

# Polaris on Kubernetes

Fairwinds' Polaris is an open-source policy agent, which helps you to ensure that your cluster aligns with best practices, in the areas of security, reliability, networking and efficiency.

![polaris health report](/images/polaris.png){ loading=lazy }

## {{ page.meta.slug }} requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] An [Ingress controller](/kubernetes/ingress/) to route incoming traffic to services

    Optional:

    * [ ] [External DNS](/kubernetes/external-dns/) to create an DNS entry the "flux" way

{% include 'kubernetes-flux-namespace.md' %}
{% include 'kubernetes-flux-helmrepository.md' %}
{% include 'kubernetes-flux-kustomization.md' %}
{% include 'kubernetes-flux-dnsendpoint.md' %}
{% include 'kubernetes-flux-helmrelease.md' %}

#### Enable dashboard

Initially you'll probably want to use the dashboard, without the webhook, so you'll want to at least enable the ingress for the dashboard (*which, itself, is enabled by default*):

```yaml hl_lines="5"
  values:
    dashboard:
      ingress:
        # dashboard.ingress.enabled -- Whether to enable ingress to the dashboard
        enabled: true
```

{% include 'kubernetes-flux-check.md' %}

## Check your score

Browse to the URL you configured for your ingress above (*it may take a while for the report to run*), and confirm that Polaris is displaying your cluster overview / score.

Now pick yourself up off the floor.. some of the issues are false-positives![^1]

## Improve your score

You may not care about some of the checks being applied. For example, you may using a single-node cluster, and so the HA / resilience checks may be immaterial to you.

### Selectively disable checks

The [Polaris Documentation](https://polaris.docs.fairwinds.com/customization/checks/) explains how to change the `config` section of `values.yaml`. You can change the priority (*ignore, warning, etc*) of various checks. Here's how it looks on a cluster I manage:

```yaml
config:
  checks:
    # reliability
    deploymentMissingReplicas: warning
    priorityClassNotSet: ignore
    tagNotSpecified: danger
    pullPolicyNotAlways: ignore
    readinessProbeMissing: warning
    livenessProbeMissing: ignore # Per https://github.com/zegl/kube-score/blob/master/README_PROBES.md, we don't _need_ liveness probes if we have readiness probes
    pdbDisruptionsIsZero: warning
    missingPodDisruptionBudget: ignore
    topologySpreadConstraint: ignore # we don't have complex topology
    <truncated>
```

### Add exceptions 

You may want a check running, but want to ignore results from a particular namespace[. This can be done using annotations on individual workloads, ](https://polaris.docs.fairwinds.com/customization/exemptions/#annotations), but I prefer to codify these in Polaris' config, so that all my exemptions are stored (*and versioned*) in one place:

#### Using config

Exemptions are also configured under `config`, as illustrated below:

```yaml
config:
  exemptions:
    - namespace: kube-system
      controllerNames:
        - kube-apiserver
        - kube-proxy
        - kube-scheduler
        - etcd-manager-events
        - kube-controller-manager
        - kube-dns
        - etcd-manager-main
      rules:
        - hostPortSet
        - hostNetworkSet
        - readinessProbeMissing
        - cpuRequestsMissing
        - cpuLimitsMissing
        - memoryRequestsMissing
        - memoryLimitsMissing
        - runAsRootAllowed
        - runAsPrivileged
        - notReadOnlyRootFilesystem
        - hostPIDSet

    # Special case for Cilium
    - namespace: kube-system
      controllerNames: 
        - cilium
      rules:
        - runAsRootAllowed
```

#### Using annotations

To exempt a controller from all checks via annotations, use the annotation `polaris.fairwinds.com/exempt=true`, e.g.

`kubectl annotate deployment my-deployment polaris.fairwinds.com/exempt=true`

To exempt a controller from a particular check via annotations, use an annotation in the form of `polaris.fairwinds.com/<check>-exempt=true`, e.g.

`kubectl annotate deployment my-deployment polaris.fairwinds.com/cpuRequestsMissing-exempt=true`

Here's an example from the clusterRolebinding used for [authentik][k8s/authentik]:

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: oidc-group-admin-kube-apiserver
  annotations:
    polaris.fairwinds.com/clusterrolebindingPodExecAttach-exempt: "true"
    polaris.fairwinds.com/clusterrolebindingClusterAdmin-exempt: "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: Group
  name: oidc:admin-kube-apiserver # for authentik
- kind: Group
  name: admin-kube-apiserver # for weave-gitops
```

## Summary

What have we achieved? We've deployed Polaris, which we can use for a point-in-time audit of our cluster's best-practice configuration, or even as a webhook to prevent "uncomplaint" configuration from being applied in the first place! :muscle:

!!! summary "Summary"
    Created:

    * [X] Polaris deployend and ready to improve our cluster security, resiliency, and efficiency !

    Next:

    * [ ] Work your way through the **legitimate** issues highlighted by Polaris, make improvements, and refresh the report page, gradually working your way up to an A+ "smooth sailing" cluster! :sun:

{% include 'recipe-footer.md' %}

[^1]: You'd be surprised how many are **not** false positives though - especially workloads deployed from 3rd-party helm charts, which are usually defaulted to the most generally compatible configurations.