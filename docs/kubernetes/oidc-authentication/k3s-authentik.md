---
title: Configure K3s for OIDC authentication with Authentik
description: How to configure your K3s Kubernetes cluster for OIDC authentication with Authentik
---
# Authenticate to Kubernetes with OIDC on K3s

This recipe describes how to configure K3s for OIDC authentication against an [authentik][k8s/authentik] instance. 

For details on **why** you'd want to do this, see the [Kubernetes Authentication Guide](/kubernetes/oidc-authentication/).

## Requirements

!!! summary "Ingredients"

    * [x] A [Kubernetes cluster](/kubernetes/cluster/) deployed using [K3S](/kubernetes/cluster/k3s)
    * [x] [authentik][k8s/authentik] deployed per the recipe
    * [x] authentik [configured as an OIDC provider for kube-apiserver](/kubernetes/oidc-authentication/authentik/)

## Setup K3s for OIDC auth

If you followed the k3s install guide, you'll have installed K3s with a command something like this:

```bash
MYSECRET=iambatman
curl -fL https://get.k3s.io | K3S_TOKEN=${MYSECRET} \
    sh -s - --disable traefik server
```

To configure the apiserver to perform OIDC authentication, you need to add some extra kube-apiserver arguments. There are two ways to do this:

1. Append the arguments to your `curl | bash` command, like a lunatic
2. Add the arguments to a config file which K3s will parse upon start, like a gentleman

Here's the lunatic option:

```bash title="Lunatic curl | bash option"
--kube-apiserver-arg=oidc-issuer-url=https://authentik.example.com/application/o/kube-apiserver/
--kube-apiserver-arg=oidc-client-id=kube-apiserver
--kube-apiserver-arg=oidc-username-claim=email
--kube-apiserver-arg=oidc-groups-claim=groups
--kube-apiserver-arg=oidc-username-prefix='oidc:'
--kube-apiserver-arg=oidc-groups-prefix='oidc:'
```

And here's the gentlemanly option:

Created `/etc/rancher/k3s/config.yaml`, and add:

```yaml title="Gentlemanly YAML config option"
kube-apiserver-arg:
- "oidc-issuer-url=https://authentik.infra.example.com/application/o/kube-apiserver/"
- "oidc-client-id=kube-apiserver"
- "oidc-username-claim=email"
- "oidc-groups-claim=groups"
- "oidc-username-prefix='oidc:'"
- "oidc-groups-prefix='oidc:'"
```

Now restart k3s (*`systemctl restart k3s` on Ubuntu*), and confirm it starts correctly by watching the logs (*`journalctl -u k3s -f` on Ubuntu*)

Assuming nothing explodes, you're good-to-go on attempting to actually connect...

### Install kubelogin

For CLI-based access to your cluster, you'll need a "helper" to perform the OIDC magic on behalf of kubectl. Install [int128/kubelogin](https://github.com/int128/kubelogin), which is design suited to this purpose.

Use kubelogin to test your OIDC parameters, by running:

```bash
kubectl oidc-login setup \
  --oidc-issuer-url=ISSUER_URL \
  --oidc-client-id=YOUR_CLIENT_ID \
  --oidc-client-secret=YOUR_CLIENT_SECRET
```

All going well, your browser will open a new window, logging you into authentik, and on the CLI you should get output something like this:

```
~ ❯ kubectl oidc-login setup --oidc-issuer-url=https://authentik.example.com/application/o/kube-apiserver/ --oidc-client-id=kube-apiserver --oidc-client-secret=cVj4YqmB4VPcq6e7 --oidc-extra-scope=groups,email
authentication in progress...

## 2. Verify authentication

You got a token with the following claims:

{
  "iss": "https://authentik.example.com/application/o/kube-apiserver/",
  "sub": "363d4d0814dbad2d930308dc848342e328b76f925ebba0978a51ddad699022b",
  "aud": "kube-apiserver",
  "exp": 1701511022,
  "iat": 1698919022,
  "auth_time": 1698891834,
  "acr": "goauthentik.io/providers/oauth2/default",
  "nonce": "qgKevTR1gU9Mh14HzOPPCTaP_Mgu9nvY7ZhJkCeFpGY",
  "at_hash": "TRZOLHHxFxl9HB7SHCIcMw",
  "email": "davidy@example.com",
  "email_verified": true,
  "groups": [
    "authentik Admins",
    "admin-kubernetes"
  ]
}
```

Huzzah, authentication works! :partying_face: 

!!! tip 
    Make sure you see a groups claim in the output above, and if you don't revisit your scope mapper and your claims in the provider under advanced protocol settings!

### Assemble your kubeconfig

Your kubectl access to k3s uses a kubeconfig file at `/etc/rancher/k3s/k3s.yaml`. Treat this file as a root password - it's includes a long-lived token which gives you clusteradmin ("*god mode*" on your cluster.)

Copy the `k3s.yaml` file to your local desktop (*the one with a web browser*), into `$HOME/.kube/config`, and modify it, changing `server: https://127.0.0.1:6443` to match the URL of (*one of*) your control-plane node(*s*).

Test using `kubectl cluster-info` locally, ensuring that you have access.

Amend the kubeconfig file for your OIDC user, by running a variation of:

```bash
kubectl config set-credentials oidc \
 --exec-api-version=client.authentication.k8s.io/v1beta1 \
 --exec-command=kubectl \
 --exec-arg=oidc-login \
 --exec-arg=get-token \
 --exec-arg=--oidc-issuer-url=https://authentik.example.com/application/o/kube-apiserver/ \
 --exec-arg=--oidc-client-id=kube-apiserver \
 --exec-arg=--oidc-client-secret=<your client secret> \
 --exec-arg=--oidc-extra-scope=groups \
 --exec-arg=--oidc-extra-scope=email
```

Test your OIDC powerz by running `kubectl --user=oidc cluster-info`.

Now gasp in dismay as you discover that your request was denied for lack of access! :scream:

```
Error from server (Forbidden): services is forbidden: User "oidc:davidy@funkypenguin.co.nz" 
cannot list resource "services" in API group "" in the namespace "kube-system"
```

### Create clusterrolebinding

That's what you wanted, right? Security? Locking out unauthorized users? Ha.

Now that we've confirmed that kube-apiserver knows your **identity** (authn), create a clusterrolebinding to tell it what your identity is **authorized** to do (authz), based on your group membership.

The following is a simple clusterrolebinding which will grant all members of the `admin-kube-apiserver` full access (`cluster-admin`), to get you started:

```yaml title="/authentic/clusterrolebinding-oidc-group-admin-kube-apiserver.yaml"
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: oidc-group-admin-kube-apiserver
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin # (1)!
subjects:
- kind: Group
  name: oidc:admin-kube-apiserver # (2)!
```

1. The role to bind
2. The subject (group, in this case) of the binding

Apply your clusterrolebinding using the usual GitOps magic (*I put mine in `/authentic/clusterrolebinding-oidc-group-admin-kube-apiserver.yaml`*).

Run `kubectl --user=oidc cluster-info` again, and confirm you are now authorized to see the cluster details.

If this works, set your user context permanently, using `kubectl config set-context --current --user=oidc`.

!!! tip "whoami?"
    Run `kubectl krew install whoami` to install the `whoami` plugin, and then `kubectl whoami` to confirm you're logged in with your OIDC account

You now have OIDC-secured CLI access to your cluster!

## Summary

What have we achieved?

We've setup our K3s cluster to authenticate against authentik, running on that same cluster! We can now create multiple users (*with multiple levels of access*) without having to provide them with tricky IAM accounts, and deploy kube-apiserver-integrated tools like Kubernetes Dashboard or Weaveworks GitOps for nice secured UIs.

!!! summary "Summary"
    Created:

    * [X] EKS cluster with OIDC authentication against [authentik][k8s/authentik]
    * [X] Ability to support:
        * [X] Kubernetes Dashboard (*coming soon*)
        * [X] Weave GitOps (*coming soon*)
    * [X] We've also retained our static, IAM-based `kubernetes-admin` credentials in case OIDC auth fails at some point (*keep them safe!*)

What's next? 

Deploy Weave GitOps to visualize your Flux / GitOps state, and Kubernetes Dashboard for UI management of your cluster!

[^1]: Later on, as we add more applications which need kube-apiserver authentication, we'll add more redirect URIs.

{% include 'recipe-footer.md' %}
