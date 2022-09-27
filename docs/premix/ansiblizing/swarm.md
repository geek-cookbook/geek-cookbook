# Ansiblizing a recipe for Swarm

!!! warning "This section is under construction :hammer:"
    This section is a serious work-in-progress, and reflects the current development on the [sponsors](https://github.com/sponsors/funkypenguin)' "premix" repository
    So... There may be errors and inaccuracies. Jump into [Discord](http://chat.funkypenguin.co.nz) in the #premium-support channel if you're encountering issues 😁

## Update deploy.yml

Edit `ansible/deploy.yml`, and find the swarm section, starting with:

```yaml
### non-critical swarm recipes start here, alphabeticized
```

Add an `import_role` task like this (*alphabeticized*) at the bottom:

```yaml
# Setup immich
- { import_role: { name: docker-stack }, vars: { recipe: immich }, tags: [ immich ], when: combined_config.immich.enabled | bool }
```

## Update config

Edit `ansible/group_vars/all/main.yml`, and edit the `recipe_default_config` dictionary, adding the necessary values, like this:

```yaml
immich:
  enabled: false #(1)!
  run_pre_deploy: | #(2)!
    mkdir -p /var/data/immich/database-dump
    mkdir -p /var/data/immich/upload
    mkdir -p /var/data/runtime/immich/database 
  run_post_deploy: | #(3)!
    echo "this is just an example to show that it's possible to run tasks post-deploy!"
```

1. We disable all non-essential services by default - that way, the user can opt into them in their own config, which is later merged with this master config.
2. Add as many pre-deploy commands as necessary - typically these will create the necessary data directories. `/var/data/config/<recipe>` will be created automatically.
3. Likewise, add any necessary post-deployment commands

## Ensure the recipe files are valid

The playbook assumes that `/<recipe-name>/<recipe-name>.yml` and `/<recipe-name>/<recipe-name>.env-sample` exist. Without these (*and any other supporting files, ending in `-sample`*), unpleasant things will happen!
