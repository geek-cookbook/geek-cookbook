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
