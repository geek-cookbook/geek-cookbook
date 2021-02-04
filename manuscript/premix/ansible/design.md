# Premix via Ansible

!!! warning "This section is under construction :hammer:"
    This section is a serious work-in-progress, and reflects the current development on the [sponsors](https://github.com/sponsors/funkypenguin)'s "premix" repository
    So... There may be errors and inaccuracies. Jump into [Discord](http://chat.funkypenguin.co.nz) in the #dev channel if you're encountering issues 😁

## Design

The ansible playbooks / roles in premix are intended to automate the deployment of an entire stack, along with selected recipes. The following design decisions influenced how the playbook is written:

1. Users should be able to pull down updates to the repo without encountering conflicts in config files etc which they've changed.
2. Secrets should be stored securely
3. Configuration should be centralized (i.e., one place to manage changes)
4. Duplication should be avoided
5. The user is running in a self-managed, isolated environment, and secret storage is non-critical

## Details

**Duplication should be avoided**

This means that ansible will use the same source files which we use to deploy swarm stacks manually (*i.e., /kanboard/*). This has some implications:

1. Whenever a recipe requires more than just a .yml file, we provide "sample" files. The intention of sample files is to give the user direction on what to customize in order to deploy the stack. The sample files are named for their "real" counterparts, with `-sample` suffixed. For example, the sample file for `traefikv1/traefik.toml` is `traefikv1/traefik.toml-sample`. During ansible deployment, if the "real" version of the file doesn't exist, it'll be created from a copy of the sample file. However, if the user has already created teh "real" file, it'll remain untouched.

!!! question "Why do we do this?"

    In an ansible-based deployment, we **don't** clone the premix repo to /var/data/config. Instead, we clone it somewhere local, and then use the playbook to launch the stack, including the creation of ceph shared storage at /var/data/config. The necessary files are then **copied** from the cloned repo into `/var/data/config`, so that they can be altered by the user, backed up, etc. This separation of code from config makes it easier for users to pull down updates to the premix repo, without having to worry about merge conflicts etc for the files they've manually changed during deployment.

**Configuration should be centralized**

What we _don't_ want, is to manually be editing `<recipe>/<recipe>.env` files all over, and tracking changes to all of these. To this end, there's a `config` dictionary defined, which includes a subsection for each recipe. Here's an example:

```yaml
config:
  traefik:
    dns_provider: route53
    env:
      # if you're using cloudflare
      # cloudflare_email: 
      # cloudflare_api_key:

      # if you're using route53
      AWS_ACCESS_KEY_ID: {{ "{{ vault_config.traefik.aws_access_key_id }}" }}
      AWS_SECRET_ACCESS_KEY: {{ "{{ vault_config.traefik.aws_secret_access_key }}" }}
      AWS_REGION: ""
```