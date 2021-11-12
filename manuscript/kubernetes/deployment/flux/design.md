# Design

!!! question "Shouldn't a design **precede** installation instructions?"
    In this case, I felt that an [installation](/kubernetes/deployment/flux/install/) and a practical demonstration upfront, would help readers to understand the flux design, and make it simpler to then explain how to [operate](/kubernetes/deployment/flux/operate/) flux themselves! 💪

Flux is power and flexible enough to fit many use-cases. After some experience and dead-ends, I've worked out a way to deploy Flux with enough flexibility but structure to make it an almost-invisible part of how my cluster "just works" on an ongoing basis..

## Diagram

Consider this entity relationship diagram:

``` mermaid
    erDiagram
          repo-path-flux-system ||..|{ app-namespace : "contains yaml for"
          repo-path-flux-system ||..|{ app-kustomization : "contains yaml for"
          repo-path-flux-system ||..|{ helmrepositories : "contains yaml for"

          app-kustomization ||..|| repo-path-app : "points flux at"

          flux-system-kustomization ||..|| repo-path-flux-system : "points flux at"

          repo-path-app ||..|{ app-helmreleases: "contains yaml for"
          repo-path-app ||..|{ app-configmap: "contains yaml for"
          repo-path-app ||..|o app-sealed-secrets: "contains yaml for"
          
          app-configmap ||..|| app-helmreleases : configures
          helmrepositories ||..|| app-helmreleases : "host charts for"
          
          app-helmreleases ||..|{ app-containers : deploys
          app-containers }|..|o app-sealed-secrets : references
```

## Explanation

And here's what it all means, starting from the top...

1. The flux-system **Kustomization** tells flux to look in the repo in `/flux-system`, and apply any YAMLs it finds (*with optional kustomize templating, if you're an uber-ninja!*). 
2. Within `/flux-system`, we've defined (for convenience), 3 subfolders, containing YAML for:
      1. `namespaces` : Any other **Namespaces** we want to deploy for our apps
      2. `helmrepositories` : Any **HelmRepositories** we later want to pull helm charts from
      3. `kustomizations` : An **Kustomizations** we need to tell flux to import YAMLs from **elsewhere** in the repository
3. In turn, each app's **Kustomization** (*which we just defined above*) tells flux to look in the repo in the `/<app name>` path, and apply any YAMLs it finds (*with optional kustomize templating, if you're an uber-ninja!*). 
4. Within the `/<app name>` path, we define **at least** the following:
      1. A **HelmRelease** for the app, telling flux which version of what chart to apply from which **HelmRepository**
      2. A **ConfigMap** for the HelmRelease, which contains all the custom (*and default!*) values for the chart
5. Of course, we can also put any **other** YAML into the `/<app name>` path in the repo, which may include additional ConfigMaps, SealedSecrets (*for safely storing secrets in a repo*), Ingresses, etc.

!!! question "That seems overly complex!"
    > "Why not just stick all the YAML into one folder and let flux reconcile it all-at-once?"

    Several reasons:

    * We need to be able to deploy multiple copies of the same helm chart into different namespaces. Imagine if you wanted to deploy a "postgres" helm chart into a namespace for KeyCloak, plus another one for NextCloud. Putting each HelmRelease resource into its own namespace allows us to do this, while sourcing them all from a common HelmRepository
    * As your cluster grows in complexity, you end up with dependency issues, and sometimes you need one chart deployed first, in order to create CRDs which are depended upon by a second chart (*like Prometheus' ServiceMonitor*). Isolating apps to a kustomization-per-app means you can implement dependencies and health checks to allow a complex cluster design without chicken vs egg problems! 

## Got it?

Good! I describe how to put this design into action on the [next page](/kubernetes/deployment/flux/operate/)...

[^1]: ERDs are fancy diagrams for nERDs which [represent cardinality between entities](https://en.wikipedia.org/wiki/Entity%E2%80%93relationship_model#Crow's_foot_notation) scribbled using the foot of a crow 🐓

--8<-- "recipe-footer.md"