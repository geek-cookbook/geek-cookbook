---
title: How Cilium 1.14 solved a security issue by breaking toService-toPort policies
date: 2023-10-19
tags:
  - cilium
  - kubernetes
categories:
  - note
description: How to rewrite your CiliumNetworkPolicies to be secure, and 1.14-compatible
---
I've been working with a client on upgrading a Cilium v1.13 instance to v1.14.. and as usual, chaos ensued.. here's what you need to know before upgrading to Cilium v1.14...

<!-- more -->

## What happened?

!!! summary "Background"
		We use CiliumNetworkPolicies selectively, locking down some namespaces to permitted ingress/egress only, and allowing others free reign (*we also use [Istio for namespace isolation](https://www.funkypenguin.co.nz/blog/istio-namespace-isolation-tricks/)*)

The first clue was, things broke. Pods with istio-proxy sidecars weren't able to talk to istiod, and consequently pods were crashlooping all over the place. The second clue was this line in cilium's output:

```
level=warning msg="Unable to add CiliumNetworkPolicy" 
ciliumNetworkPolicyName=kube-cluster-namespace-defaults error="Invalid 
CiliumNetworkPolicy spec: 
Combining ToServices and ToPorts is not supported yet"
k8sApiVersion=cilium.io/v2 k8sNamespace=rainloop subsys=k8s-watcher
```

I didn't think too much of it initially, because (a) I wasn't changing policies, and (b) everything was working under 1.13, so I reasoned that something which wasn't supported "yet" sounded like a new feature (*which I obviously wasn't using*) and, didn't seem likely to affect the configuration / policies I'd already been running on previous versions.

Ha.

Eventually I conceded that this error was the most likely cause of my issues, so I searched for the string in the [cilium/cilium repo](https://github.com/cilium/cilium/). Sure enough, I found a [recent commit](https://github.com/cilium/cilium/commit/7959bf5b3ca1428481391b6ee001aff931b2753e) indicating a change in supported functionality.

## What was the impact?

Fortunately, this client's environment is quite mature, and all changes are deployed on multiple CI clusters (automated and manual), before being deployed into prod. So, the CI clusters were a mess, but prod was unaffected (*which is why we test all updates in CI!*)
## Why did it happen?

Why was a previously-working function marked as "not yet supported?"

Turns out what **actually** happened is that it was previously possible to create an egress policy matching a Kubernetes service in a particular namespace, and restricted to certain ports. For example, this policy "worked"[^1] in Cilium 1.13:

```yaml title="CiliumNetworkPolicy working in Cilium v1.13"
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "allow-minio-restore-egress-cluster-vault"
  namespace: minio
spec:
  endpointSelector:
    matchLabels:
      io.cilium.k8s.policy.serviceaccount: minio-restore
  egress:
    - toServices:
      - k8sService:
          serviceName: cluster-vault
          namespace: vault
      toPorts:
        - ports:
          - port: '8200'
            protocol: TCP

```

But as described in [this issue](https://github.com/cilium/cilium/issues/20067), what the above policy _actually_ does (*because k8sService only works on services without a selector :facepalm:*), is permit **any** egress on TCP port 8200 :scream:

The solution was to flip the switch on the toServices/toPorts combo, making it unsupported in Cilium 1.14, which caused the policies to fail to load (*no more unlimited egress!*).

## How was it fixed?

In my case, this meant a bulk update of 40-50 policies, but it turns out that a "supported" fix was relatively simple. The `toEndpoints` egress selector can achieve the same result. The gotcha is you need to match on your target services' label, as well as the cilium-specific `k8s:io.kubernetes.pod.namespace` label, which indicates which namespace the target pods can be found in.

!!! note "What about targeting services in the same namespace?"
		It seems that unless the `k8s:io.kubernetes.pod.namespace` is found in the policy, the policy will only apply to pods in the namespace in which is found. This is a subtle change in behaviour which could easily result in confusion - i.e., you'd assume that omitting the `k8s:io.kubernetes.pod.namespace` tag would result in matching endpoints across the **entire** cluster (*and why would you do that?*)

So I changed this:

```yaml
    - toServices:
      - k8sService:
          serviceName: cluster-vault
          namespace: vault
```

To this:

```yaml
    - toEndpoints:
      - matchLabels:
          app.kubernetes.io/name: vault
          k8s:io.kubernetes.pod.namespace: vault  
```

Here's the entirety of my new policy:
```yaml title="CiliumNetworkPolicy updated to work in Cilium v1.14"
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "allow-minio-restore-egress-cluster-vault"
  namespace: minio
spec:
  endpointSelector:
    matchLabels:
      io.cilium.k8s.policy.serviceaccount: minio-restore
  egress:
    - toEndpoints:
      - matchLabels:
          app.kubernetes.io/name: vault
          k8s:io.kubernetes.pod.namespace: vault  
      toPorts:
        - ports:
          - port: '8200'
            protocol: TCP

```

[^1]: "Worked" in that it permitted egress to **any** host on the specified ports! :scream:

--8<-- "blog-footer.md"