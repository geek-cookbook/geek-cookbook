---
title: Install Mastodon in Kubernetes
description: How to install your own Mastodon instance using Kubernetes
---

# Install Mastodon in Kubernetes

[Mastodon](https://joinmastodon.org/) is an open-source, federated (*i.e., decentralized*) social network, inspired by Twitter's "microblogging" format, and used by upwards of 4.4M early-adopters, to share links, pictures, video and text.

![Mastodon Screenshot](/images/mastodon.png){ loading=lazy }

!!! question "Why would I run my own instance?"
    That's a good question. After all, there are all sorts of public instances available, with a [range of themes and communities](https://joinmastodon.org/communities). You may want to run your own instance because you like the tech, because you just think it's cool :material-emoticon-cool-outline:

    You may also have realized that since Mastodon is **federated**, users on your instance can follow, toot, and interact with users on any other instance!

    If you're **not** into that much effort / pain, you're welcome to [join our instance][community/mastodon] :material-mastodon:

## Mastodon requirements

!!! summary "Ingredients"

    Already deployed:

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) (*not running Kubernetes? Use the [Docker Swarm recipe instead][mastodon]*)
    * [x] [Flux deployment process](/kubernetes/deployment/flux/) bootstrapped
    * [x] An [Ingress](/kubernetes/ingress/) to route incoming traffic to services
    * [x] [Persistent storage](/kubernetes/persistence/) to store persistent stuff
    * [x] [External DNS](/kubernetes/external-dns/) to create an DNS entry

    New:

    * [ ] Chosen DNS FQDN for your epic new social network
    * [ ] An S3-compatible bucket for serving media (*I use [Backblaze B2](https://www.backblaze.com/b2/docs/s3_compatible_api.html)*)
    * [ ] An SMTP gateway for delivering email notifications (*I use [Mailgun](https://www.mailgun.com/)*)
    * [ ] A business card, with the title "[*I'm CEO, Bitch*](https://nextshark.com/heres-the-story-behind-mark-zuckerbergs-im-ceo-bitch-business-card/)"

## Preparation

### GitRepository

The Mastodon project doesn't currently publish a versioned helm chart - there's just a [helm chart stored in the repository](https://github.com/mastodon/mastodon/tree/main/chart) (*I plan to submit a PR to address this*). For now, we use a GitRepository instead of a HelmRepository as the source of a HelmRelease.

```yaml title="/bootstrap/gitrepositories/gitepository-mastodon.yaml"
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: mastodon
  namespace: flux-system
spec:
  interval: 1h0s
  ref:
    branch: main
  url: https://github.com/funkypenguin/mastodon # (1)!
```

1. I'm using my own fork because I've been working on improvements to the upstream chart, but `https://github.com/mastodon/mastodon` would work too.

### Namespace

We need a namespace to deploy our HelmRelease and associated ConfigMaps into. Per the [flux design](/kubernetes/deployment/flux/), I create this example yaml in my flux repo at `/bootstrap/namespaces/namespace-mastodon.yaml`:

```yaml title="/bootstrap/namespaces/namespace-mastodon.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: mastodon
```

### Kustomization

Now that the "global" elements of this deployment (*just the GitRepository in this case*) have been defined, we do some "flux-ception", and go one layer deeper, adding another Kustomization, telling flux to deploy any YAMLs found in the repo at `/mastodon`. I create this example Kustomization in my flux repo:

```yaml title="/bootstrap/kustomizations/kustomization-mastodon.yaml"
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: mastodon
  namespace: flux-system
spec:
  interval: 15m
  path: mastodon
  prune: true # remove any elements later removed from the above path
  timeout: 2m # if not set, this defaults to interval duration, which is 1h
  sourceRef:
    kind: GitRepository
    name: flux-system
  validation: server
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: mastodon-web
      namespace: mastodon
    - apiVersion: apps/v1
      kind: Deployment
      name: mastodon-streaming
      namespace: mastodon
    - apiVersion: apps/v1
      kind: Deployment
      name: mastodon-sidekiq
      namespace: mastodon
```

### ConfigMap

Now we're into the mastodon-specific YAMLs. First, we create a ConfigMap, containing the entire contents of the helm chart's [values.yaml](https://github.com/bitnami-labs/mastodon/blob/main/helm/mastodon/values.yaml). Paste the values into a `values.yaml` key as illustrated below, indented 4 tabs (*since they're "encapsulated" within the ConfigMap YAML*). I create this example yaml in my flux repo:

```yaml title="mastodon/configmap-mastodon-helm-chart-value-overrides.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: mastodon-helm-chart-value-overrides
  namespace: mastodon
data:
  values.yaml: |-  # (1)!
    # <upstream values go here>
```

1. Paste in the contents of the upstream `values.yaml` here, intended 4 spaces, and then change the values you need as illustrated below.

Values I change from the default are:

```yaml
spec:
  values:
    mastodon:
      createAdmin:
        enabled: true
        username: funkypenguin
        email: davidy@funkypenguin.co.nz
      local_domain: so.fnky.nz
      s3:
        enabled: true
        access_key: "<redacted>"
        access_secret: "<redacted>"
        bucket: "so-fnky-nz"
        endpoint: https://s3.us-west-000.backblazeb2.com
        hostname: s3.us-west-000.backblazeb2.com
      secrets:
        secret_key_base: "<redacted>"
        otp_secret: "<redacted>"
        vapid:
          private_key: "<redacted>"
          public_key: "<redacted>"
      smtp:
        domain: mg.funkypenguin.co.nz
        enable_starttls_auto: true
        from_address: mastodon@mg.funkypenguin.co.nz
        login: mastodon@mg.funkypenguin.co.nz
        openssl_verify_mode: peer
        password: <redacted>
        port: 587
        reply_to: mastodon@mg.funkypenguin.co.nz
        server: smtp.mailgun.org
        tls: false

ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: traefik
        nginx.ingress.kubernetes.io/proxy-body-size: 10m
      hosts:
        - host: so.fnky.nz
          paths:
            - path: '/'

    postgresql:
      auth:
        postgresPassword: "<redacted>"
        username: postgres
        password: "<redacted>"
      primary:
        persistence:
          size: 1Gi

    redis:
      password: "<redacted>"
      master:
        persistence:
          size: 1Gi
      architecture: standalone
```

### HelmRelease

Finally, having set the scene above, we define the HelmRelease which will actually deploy the mastodon into the cluster. I save this in my flux repo:

```yaml title="/mastodon/helmrelease-mastodon.yaml"
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: mastodon
  namespace: mastodon
spec:
  chart:
    spec:
      chart: ./charts/mastodon
      sourceRef:
        kind: GitRepository
        name: mastodon
        namespace: flux-system
  interval: 15m
  timeout: 5m
  releaseName: mastodon
  valuesFrom:
  - kind: ConfigMap
    name: mastodon-helm-chart-value-overrides
    valuesKey: values.yaml # (1)!
```

1. This is the default, but best to be explicit for clarity

## :material-mastodon: Install Mastodon!

Commit the changes to your flux repository, and either wait for the reconciliation interval, or force  a reconcilliation[^1] using `flux reconcile source git flux-system`. You should see the kustomization appear...

```bash
~ ❯ flux get kustomizations | grep mastodon
mastodon                 	main/d34779f	False    	True 	Applied revision: main/d34779f
~ ❯
```

The helmrelease should be reconciled...

```bash
~ ❯ flux get helmreleases -n mastodon 
NAME    	REVISION    	SUSPENDED	READY	MESSAGE
mastodon	1.2.2-pre-02	False    	True 	Release reconciliation succeeded
~ ❯
```

And you should have happy Mastodon pods:

```bash
~ ❯ k get pods -n mastodon
NAME                                   READY   STATUS      RESTARTS   AGE
mastodon-media-remove-27663840-l2xvt   0/1     Completed   0          22h
mastodon-postgresql-0                  1/1     Running     0          5d20h
mastodon-redis-master-0                1/1     Running     0          5d20h
mastodon-sidekiq-5ffd544f98-k86qp      1/1     Running     0          5d20h
mastodon-streaming-676fdcf75-hz52z     1/1     Running     0          5d20h
mastodon-web-597cf7c8d5-2hzkl          1/1     Running     4          5d20h
~ ❯
```

... and finally check that the ingress was created as desired:

```bash
~ ❯ k get ingress -n mastodon
NAME       CLASS    HOSTS        ADDRESS   PORTS     AGE
mastodon   <none>   so.fnky.nz             80, 443   8d
~ ❯
```

Now hit the URL you defined in your config, and you should see your beautiful new Mastodon instance! Login with your configured credentials, navigate to **Preferences**, and have fun tweaking and tooting away!

!!! question "What's my Mastodon admin password?"

    The admin username _may_ be output by the post-install hook job which creates it, but I didn't notice this at the time I deployed mine. Since I had a working SMTP setup however, I just used the "forgot password" feature to perform a password reset, which feels more secure anyway.

Once you're done, "toot" me up by mentioning [funkypenguin@so.fnky.nz](https://so.fnky.nz/@funkypenguin) in a toot! :wave:

!!! tip
    If your instance feels lonely, try using some [relays](https://github.com/brodi1/activitypub-relays) to bring in the federated firehose!

## Summary

What have we achieved? We now have a fully-swarmed Mastodon instance, ready to federate with the world! :material-mastodon:

!!! summary "Summary"
    Created:

    * [X] Mastodon configured, running, and ready to toot!

--8<-- "recipe-footer.md"

[^1]: There is also a 3rd option, using the Flux webhook receiver to trigger a reconcilliation - to be covered in a future recipe!
