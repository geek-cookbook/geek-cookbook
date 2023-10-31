---
title: Install Matrix in Kubernetes
description: How to install your own Matrix instance using Kubernetes
status: new
---

# Install Invidious in Kubernetes

## gotchas

Create signing key first. Else you'll ban yourself from the federation!

```bash
~ ❯ docker run --rm -it ananace/matrix-synapse generate_signing_key                                                                                             ed25519 a_cQgt sOaAmEl7a9s2S0RCr7FT9nzuSjEjYVRrNNzwIKsutzA
~ ❯
```

Thanks to [Sealed Secrets](/kubernetes/sealed-secrets/), we have a safe way of committing secrets into our repository, so to create this cloudflare secret, you'd run something like this:

```bash
  kubectl create secret generic matrix-synapse-signingkey \
  --namespace matrix \
  --dry-run=client \
  --from-literal=signing.key=YOURSIGNINGKEYGOESHERE -o json \
  | kubeseal --cert <path to public cert> \
  > <path to repo>/matrix/sealedsecret-matrix-synapse-signingkey.yaml
```

Why not Dendrite?

AFAIK, it woen't yet work with SSO (login with GitHub), and requires nats for messaging, which will consume more PVCs on my limited DO cluster!

### Create matrix_media_repo database

```bash
kubectl exec -n matrix matrix-synapse-postgresql-0 -it -- \
/bin/bash -c PGPASSWORD=$POSTGRES_PASSWORD createdb matrix_media_repo -U synapse
```

### Create mautrix-discord database

```bash
kubectl exec -n matrix matrix-synapse-postgresql-0 -it -- \
/bin/bash -c PGPASSWORD=$POSTGRES_PASSWORD createdb matrix_discord -U synapse # (1)!
```

1. No hyphens allowed in database names, apparently!

### Register admin user

kubectl -n matrix exec -it $(kubectl -n matrix get pod -l "app.kubernetes.io/name=matrix-synapse" -o jsonpath='{.items[0].metadata.name}') /bin/bash

```bash
root@matrix-synapse-5d7cf8579-zjk7c:/# register_new_matrix_user -k '<MY REGISTRATION KEY>' https://matrix.funkypenguin.co.nz
New user localpart [root]: root
Password:
Confirm password:
Make admin [no]: yes
Sending registration request...
Success!
root@matrix-synapse-5d7cf8579-zjk7c:/#
```

