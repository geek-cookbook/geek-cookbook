---
date: 2023-02-11
categories:
  - note
tags:
  - kubernetes
  - security
title: Why security in-depth is a(n awesome) PITA
description: Is it easy to deploy stuff into your cluster? Ha! 0wn3d. It's SUPPOSED to be a PITA!
---

# Security in depth / zero trust is a 100% (awesome) PITA

Today I spent upwards of half my day deploying a single service into a client's cluster. Here's why I consider this to be a win...

<!-- more -->

Here's how the process went:

1. Discover [4-year-old GitHub repo](https://github.com/aikoven/foundationdb-exporter) containing the **exact** tool we needed (*a prometheus exporter for FoundationDB metrics*)
2. Attempt to upload the image into our private repo, running [Harbor](https://goharbor.io/) with vulnerability scanning via [Trivy](https://github.com/aquasecurity/trivy) enforced. Discover that it has 1191 critical CVEs, upload is blocked.
3. Rebuild image with the latest node, 4 CVEs remain. CVEs are manually whitelisted[^1]. Image can now be added to repo.
4. Image must be signed using [cosign](https://github.com/sigstore/cosign) on both the dev and prod infrastructure (*separate signing keys are used*). [Connaisseur](https://github.com/sse-secure-systems/connaisseur) prevents unsigned images from being run in any of our clusters[^2].
5. Image is in the repo, now to deploy it... add a deployment template to our existing database helm chart. Deployment pipeline (*via [Concourse CI](https://concourse-ci.org/)*) fails while [kube-scor](https://github.com/zegl/kube-score)ing / [kube-conform](https://github.com/yannh/kubeconform)ing the generated manifests, because they're missing the appropriate probes and securityContexts
6. Note that if we had been able to sneak a less-than-secure deployment past kube-score's static linting, then [Kyverno](https://kyverno.io/) would have prevented the pod from running!
7. Fixed all the invalid / less-than-best-practice elements of the deployment. Ensure resource limits, HPAs, securityContexts are applied. 
8. Manifest deploys (*pipeline is green!*), pod immediately crashloops (*it's not very obtuse code!*)
9. Examine Cilium's [Hubble](https://github.com/cilium/hubble), determine that the pod is trying to talk to FoundationDB (*duh*), and being blocked by default.
10. Apply the appropriate labels to the deployment / pod to align with the pre-existing regime of [Cilium NetworkPolicies](https://docs.cilium.io/en/latest/security/policy/) permitting ingress/egress to services based on pod labels (*thanks [Monzo](https://monzo.com/blog/we-built-network-isolation-for-1-500-services)!*)
11. No more dropped sessions in Hubble! But pod still crashloops. Apply an [Istio AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/) to permit mTLS traffic between the exporter and FoundationDB.
12. Now the exporter can talk to FoundationDB! But no metrics are being gathered.. why?
13. Apply another update to a separate policy helm chart (*which **only** contains CiliumNetworkPolicy manifests*), permitting the cluster Prometheus access to the exporter on the port it happens to prefer.

Finally, I am rewarded with metrics scraped by Prometheus, and exposed in the Grafana dashboard:

![Grafana dashboard showing FoundationDB metrics](/images/blog/foundationdb-exporter-grafana-dashboard.png)

!!! note
    It's especially gratifying to note that while all these schenanigans were going on, the existing services running in our prod and dev namespaces were completely isolated and unaffected. All changes happened in a PR branch, for which Concourse built a fresh, ephemeral namespace for every commit.

## Why is this a big deal?

I wanted to highlight how many levels of security / validation we employ in order to introduce any change into our clusters, even a simple metrics scraper. It may seem overly burdensome for a simple trial / tool, but my experience has been that "*temporary is permanent*", and the sooner you deploy something **properly**, the more resilient and reliable the whole system is.

## Do you want to be a PITA too?

This is what I love doing (*which is why I'm blogging about it at 11pm!*). If you're looking to augment / improve your Kubernetes layered security posture, [hit me up](https://www.funkypenguin.co.nz/work-with-me/), and let's talk business!

[^1]: We use ansible for this
[^2]: Yes, another Ansible process!

--8<-- "blog-footer.md"
