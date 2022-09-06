# Ansiblizing a recipe for Kubernetes

!!! warning "This section is under construction :hammer:"
    This section is a serious work-in-progress, and reflects the current development on the [sponsors](https://github.com/sponsors/funkypenguin)' "premix" repository
    So... There may be errors and inaccuracies. Jump into [Discord](http://chat.funkypenguin.co.nz) in the #premium-support channel if you're encountering issues 😁

## Update deploy.yml

Edit `ansible/deploy.yml`, and find the kubernetes section, starting with:

```yaml
# Create flux manifests using localhost
- hosts: localhost
```

Add an `import_role` task like this (*alphabeticized*) at the bottom:

```yaml
# Traefik
- { import_role: { name: flux-repo }, vars: { recipe: traefik, config: traefik }, tags: [ traefik ], when: combined_config.traefik.enabled | bool }
```

## Update config

Edit `ansible/group_vars/all/main.yml`, and edit the `recipe_default_config` dictionary, adding the necessary values, like this:

```yaml
traefik:
  enabled: true
  helm_chart_namespace: traefik
  helm_chart_name: traefik
  helm_chart_repo: traefik
  helm_chart_repo_url: https://helm.traefik.io/traefik
  helm_chart_version: latest    
```

## That's it!

What, that's all? So easy?

Yes, but remember all they playbook does in the case of a flux deployment is to create the necessary files for the user to customize themselves, since it's impractical to try to contain any chart config within our playbook!
