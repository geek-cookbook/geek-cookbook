---
description: Kubernetes Flux deployment strategy - Installation
---

# Flux Installation

[Flux](https://fluxcd.io/) is a set of continuous and progressive delivery solutions for Kubernetes that are open and extensible.

Using flux to manage deployments into the cluster means:

1. All change is version-controlled (*i.e. "GitOps"*)
2. It's not necessary to expose the cluster API (*i.e., which would otherwise be the case if you were using CI*)
3. Deployments can be paused, rolled back, examine, debugged using Kubernetes primitives and tooling

!!! summary "Ingredients"

    * [x] [Install the flux CLI tools](https://fluxcd.io/docs/installation/#install-the-flux-cli) on a host which has access to your cluster's apiserver.
    * [x] Create a GitHub [personal access token](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) that can create repositories by checking all permissions under repo.
    * [x] Create a private GitHub repository dedicated to your flux deployments

## Basics

Here's a simplified way to think about the various flux components..

1. You need a source for flux to look at. This is usually a Git repository, although it can also be a helm repository, an S3 bucket. A source defines the entire repo (*not a path or a folder structure*).
2. Within your source, you define one or more kustomizations. Each kustomization is a _location_ on your source (*i.e., myrepo/nginx*) containing YAML files to be applied directly to the API server.
3. The YAML files inside the kustomization include:
      1. HelmRepositories (*think of these as the repos you'd add to helm with `helm repo`*)
      2. HelmReleases (*these are charts which live in HelmRepositories*)
      3. Any other valid Kubernetes YAML manifests (*i.e., ConfigMaps, etc)*

## Preparation

### Install flux CLI

This section is a [direct copy of the official docs](https://fluxcd.io/docs/installation/#install-the-flux-cli), to save you having to open another tab..

=== "HomeBrew (MacOS/Linux)"

    With [Homebrew](https://brew.sh/) for macOS and Linux:
    
    ```bash
    brew install fluxcd/tap/flux
    ```

=== "Bash (MacOS/Linux)"

    With Bash for macOS and Linux:

    ```bash
    curl -s https://fluxcd.io/install.sh | sudo bash
    ```

=== "Chocolatey"

    With [Chocolatey](https://chocolatey.org/) for Windows:

    ```bash
    choco install flux
    ```


### Create GitHub Token

Create a GitHub [personal access token](https://github.com/settings/tokens) that can create repositories by checking all permissions under repo. (*we'll use the token in the bootstrapping step below*)

### Create GitHub Repo

Now we'll create a repo for flux - it can (*and probably should!*) be private. I've created a [template repo to get you started](https://github.com/geek-cookbook/template-flux/generate), but you could simply start with a blank repo too.[^1]

### Bootstrap Flux

Having prepared all of the above, we're now ready to deploy flux. Before we start, take a look at all the running pods in the cluster, with `kubectl get pods -A`. You should see something like this...

```bash
root@shredder:~# k3s kubectl get pods -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   coredns-7448499f4d-qfszx                  1/1     Running   0          6m32s
kube-system   local-path-provisioner-5ff76fc89d-rqh52   1/1     Running   0          6m32s
kube-system   metrics-server-86cbb8457f-25688           1/1     Running   0          6m32s
```

Now, run a customized version of the following:

```bash
GITHUB_TOKEN=<your-token>
flux bootstrap github \
  --owner=my-github-username \ 
  --repository=my-github-username/my-repository \
  --personal
```

Once the flux bootstrap is completed without errors, list the pods in the cluster again, with `kubectl get pods -A`. This time, you see something like this:

```
root@shredder:~# k3s kubectl get pods -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
flux-system   helm-controller-f7c5b6c56-nk7rm            1/1     Running   0          5m48s
flux-system   kustomize-controller-55db56f44f-4kqs2      1/1     Running   0          5m48s
flux-system   notification-controller-77f68bf8f4-9zlw9   1/1     Running   0          5m48s
flux-system   source-controller-8457664f8f-8qhhm         1/1     Running   0          5m48s
kube-system   coredns-7448499f4d-qfszx                   1/1     Running   0          15m
kube-system   local-path-provisioner-5ff76fc89d-rqh52    1/1     Running   0          15m
kube-system   metrics-server-86cbb8457f-25688            1/1     Running   0          15m
traefik       svclb-traefik-ppvhr                        2/2     Running   0          5m31s
traefik       traefik-f48b94477-d476p                    1/1     Running   0          5m31s
root@shredder:~#
```

### What just happened?

Flux installed its controllers into the `flux-system` namespace, and created two new objects:

1. A **GitRepository** called `flux-system`, pointing to your GitHub repo.
2. A **Kustomization** called `flux-system`, pointing to the `flux-system` directory in the above repo.

If you used my template repo, some extra things also happened..

3. I'd pre-populated the `flux-system` directory in the template repo with 3 folders:
      1. [helmrepositories](https://github.com/geek-cookbook/template-flux/tree/main/flux-system/helmrepositories), for storing repositories used for deploying helm charts
      2. [kustomizations](https://github.com/geek-cookbook/template-flux/tree/main/flux-system/kustomizations), for storing additional kustomizations *(which in turn can reference other paths in the repo*)
      3. [namespaces](https://github.com/geek-cookbook/template-flux/tree/main/flux-system/namespaces), for storing namespace manifests (*since these need to exist before we can deploy helmreleases into them*)
4. Because the `flux-system` Kustomization includes everything **recursively** under `flux-system` path in the repo, all of the above were **also** applied to the cluster
5. I'd pre-prepared a [Namespace](https://github.com/geek-cookbook/template-flux/blob/main/flux-system/namespaces/namespace-podinfo.yaml), [HelmRepository](https://github.com/geek-cookbook/template-flux/blob/main/flux-system/helmrepositories/helmrepository-podinfo.yaml), and [Kustomization](https://github.com/geek-cookbook/template-flux/blob/main/flux-system/kustomizations/kustomization-podinfo.yaml) for "podinfo", a simple example application, so these were applied to the cluster
6. The kustomization we added for podinfo refers to the `/podinfo` path in the repo, so everything in **this** folder was **also** applied to the cluster
7. In the `/podinfo` path of the repo is a [HelmRelease](https://github.com/geek-cookbook/template-flux/blob/main/podinfo/helmrelease-podinfo.yaml) (*an object describing how to deploy a helm chart*), and a [ConfigMap](https://github.com/geek-cookbook/template-flux/blob/main/podinfo/configmap-pofinfo-helm-chart-value-overrides-configmap.yaml) (*which ontain the `values.yaml` for the podinfo helm chart*)
8. Flux recognized the podinfo **HelmRelease**, applied it along with the values in the **ConfigMap**, and consequently we have podinfo deployed from the latest helm chart, into the cluster, and managed by Flux! 💪

## Wait, but why?

That's best explained on the [next page](/kubernetes/deployment/flux/design/), describing the design we're using...

--8<-- "recipe-footer.md"

[^1]: The [template repo](https://github.com/geek-cookbook/template-flux/) also "bootstraps" a simple example re how to [operate flux](/kubernetes/deployment/flux/operate/), by deploying the podinfo helm chart.