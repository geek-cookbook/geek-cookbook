---
date: 2022-11-17
categories:
  - note
tags:
  - renovate
title: How running a pod as GID 1337 can cause a Kubernetes pod to bypass istio-proxy
description: Is your pod bypassing istio-proxy? Check your GUID isn't set to 1337!
---

# Is your pod bypassing istio-proxy? Check your GUID

After spending hours debugging why a particular pod can't properly communicate with another pod via Istio's service mesh, I stumbled into the answer..

<!-- more -->

<iframe src="https://so.fnky.nz/@funkypenguin/109356967728428702/embed" class="mastodon-embed" style="max-width: 100%; border: 0" width="400" allowfullscreen="allowfullscreen"></iframe><script src="https://so.fnky.nz/embed.js" async="async"></script>

Here's more details.. Istio creates iptables rules to intercept pod-to-pod traffic. The rules look something like this (from the istio-cni pod, in my case):

```text
* nat
-N ISTIO_INBOUND
-N ISTIO_REDIRECT
-N ISTIO_IN_REDIRECT
-N ISTIO_OUTPUT
-A ISTIO_INBOUND -p tcp --dport 15008 -j RETURN
-A ISTIO_REDIRECT -p tcp -j REDIRECT --to-ports 15001
-A ISTIO_IN_REDIRECT -p tcp -j REDIRECT --to-ports 15006
-A PREROUTING -p tcp -j ISTIO_INBOUND
-A ISTIO_INBOUND -p tcp --dport 15020 -j RETURN
-A ISTIO_INBOUND -p tcp --dport 15021 -j RETURN
-A ISTIO_INBOUND -p tcp --dport 15090 -j RETURN
-A ISTIO_INBOUND -p tcp -j ISTIO_IN_REDIRECT
-A OUTPUT -p tcp -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -p tcp --dport 15020 -j RETURN
-A ISTIO_OUTPUT -o lo -s 127.0.0.6/32 -j RETURN
-A ISTIO_OUTPUT -o lo ! -d 127.0.0.1/32 -m owner --uid-owner 1337 -j ISTIO_IN_REDIRECT
-A ISTIO_OUTPUT -o lo -m owner ! --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --uid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -o lo ! -d 127.0.0.1/32 -m owner --gid-owner 1337 -j ISTIO_IN_REDIRECT
-A ISTIO_OUTPUT -o lo -m owner ! --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -m owner --gid-owner 1337 -j RETURN
-A ISTIO_OUTPUT -d 127.0.0.1/32 -j RETURN
-A ISTIO_OUTPUT -j ISTIO_REDIRECT
COMMIT
```

And the offending pod was using this:

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  privileged: false
  seccompProfile:
    type: RuntimeDefault   
  runAsNonRoot: true
  runAsUser: 10001
  runAsGroup: 1337
```

See the problem? Any traffic egressing the pod coming from a process running as GUID 1337 will bypass the iptables rules, and travel "outside" of the service mesh.

In my case, this simply caused the service to break, but if you were using Istio to enforce egress policy, this would be a gotcha!

[^1]: It turns out this was an old istio configuration no longer required in current versions

--8<-- "blog-footer.md"
