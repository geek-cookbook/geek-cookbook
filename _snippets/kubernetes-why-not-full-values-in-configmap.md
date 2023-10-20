??? question "Why not put values in a separate ConfigMap?"
    > Didn't you previously advise to put helm chart values into a separate ConfigMap?

    Yes, I did. And in practice, I've changed my mind.

    Why? Because having the helm values directly in the HelmRelease offers the following advantages:

    1. If you use the [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) extension in VSCode, you'll see a full path to the YAML elements, which can make grokking complex charts easier.
    2. When flux detects a change to a value in a HelmRelease, this forces an immediate reconciliation of the HelmRelease, as opposed to the ConfigMap solution, which requires waiting on the next scheduled reconciliation.
    3. Renovate can parse HelmRelease YAMLs and create PRs when they contain docker image references which can be updated.
    4. In practice, adapting a HelmRelease to match upstream chart changes is no different to adapting a ConfigMap, and so there's no real benefit to splitting the chart values into a separate ConfigMap, IMO.
