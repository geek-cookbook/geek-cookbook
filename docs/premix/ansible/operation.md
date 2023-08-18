# Operation

!!! warning "This section is under construction :hammer:"
    This section is a serious work-in-progress, and reflects the current development on the [sponsors](https://github.com/sponsors/funkypenguin)' "premix" repository
    So... There may be errors and inaccuracies. Jump into [Discord](http://chat.funkypenguin.co.nz) in the #dev channel if you're encountering issues 😁

The design section details **why** the ansible playbook was designed the way it is. This section outlines how to **operate** the playbook!

## Preparation

Clone the repo locally, onto whichever host you plan to deploy the playbook from. You'll need an up-to-date installation of Ansible.

Now we'll be creating 3 files..

### Hosts

Create a new file at `ansible/hosts.your-username` containing a variation on this:

```bash
[your-username:children]
proxmox_servers
proxmox_vms
swarm_nodes
k3s_masters
k3s_workers

[proxmox_servers]
splinter    ansible_host=192.168.29.3   ansible_user=root template_vm_id=201

# Declare your desired proxmox VMs here. Note that the MAC address "lines up" with_
# the IP address - this makes troubleshooting L2 issues easier under some circumstances,
# and declaring the MAC to proxmox avoids proxmox / terraform force-restarting the VMs
# when re-running the playbook.

[proxmox_vms]
donatello   ansible_host=192.168.38.102 mac=52:54:00:38:01:02 proxmox_node=splinter
leonardo    ansible_host=192.168.38.103 mac=52:54:00:38:01:03 proxmox_node=splinter
shredder    ansible_host=192.168.38.201 mac=52:54:00:38:02:01 proxmox_node=splinter
raphael     ansible_host=192.168.38.101 mac=52:54:00:38:01:01 proxmox_node=splinter
rocksteady  ansible_host=192.168.38.202 mac=52:54:00:38:02:02 proxmox_node=splinter
bebop       ansible_host=192.168.38.203 mac=52:54:00:38:02:03 proxmox_node=splinter

[swarm_nodes]
raphael     ansible_host=192.168.38.101 keepalived_priority=101 
donatello   ansible_host=192.168.38.102 keepalived_priority=102
leonardo    ansible_host=192.168.38.103 keepalived_priority=103

[k3s_masters]
shredder     ansible_host=192.168.38.201

[k3s_workers]
rocksteady   ansible_host=192.168.38.202
bebop        ansible_host=192.168.38.203
```

!!! note

    1. Replace `your-username` in the file name and in line \#1. This line makes all subsequent groups "children" of a master group based on your username, which we'll use in the following step to let you keep your configs/secrets separate from the main repo, with minimal friction.
    2. If you don't populate a section, it won't get applied. I.e., if you don't care about k8s hosts, don't create any k8s groups, and all the k8s steps in the playbook will be ignored. The same is true for swarm_nodes.

### Config

The variables used in the playbook are defined in the `ansible/group_vars/all/main.yml`. **Your** variables are going to be defined in a group_vars file based on your username, so that they're [treated with a higher preference](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) than the default values.

Create a folder under `ansible/group_vars/<your-username>` to match the group name you inserted in line \#1 of your hosts file, and copy `ansible/group_vars/all/main.yml` into this folder. Any variables found in this file will override any variables specified in `ansible/group_vars/all/main.yml`, but any variables _not_ found in your file will be inherited from `ansible/group_vars/all/main.yml`.

To further streamline config, a "empty" dictionary variable named `recipe_config` is configured in `ansible/group_vars/all/main.yml`. In your own vars file (`ansible/group_vars/<your-username>/main.yml`), populate this variable with your own preferred values, copied from `recipe_default_config`. When the playbook runs, your values will be combined with the default values.

!!! tip "Commit `ansible/group_vars/<your-username>/` to your own repo"
    For extra geek-fu, you could commit the contents of ``ansible/group_vars/<your-username>/` to your own repo, so that you can version/track your own config!

### Secrets

Wait, what about secrets? How are we going to store sensitive information, like API keys etc?

We'll always need to store some secrets, like your proxmox admin credentials. We want to do this in a way which is safe from accidental git commits, as well as convenient for repeated iterations, without having to pass secrets as variables on the command-line.

Enter [Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html#creating-encrypted-files), a handy solution for encrypting secrets in a painless way.

Create a password file, containing a vault password (*just generate one yourself*), and store it _outside_ of the repo:

```bash
echo mysecretpassword > ~/.ansible/vault-password-geek-cookbook-premix
```

Create an ansible-vault encrypted file in the `group_vars/<your-username>/vault.yml` using this password file:

```bash
ansible-vault create --encrypt-vault-id geek-cookbook-premix group_vars/<your-username>/vault.yml
```

Insert your secret values into this file (*refer to `group_vars/all/01_fake_vault.yml` for placeholders*), using a prefix of `vault_`, like this:

```bash
vault_proxmox_host_password: mysekritpassword
```

(You can always re-edit the file by running `ansible-vault edit group_vars/<your-username>/vault.yml`)

The vault file is encrypted using a secret you store outside the repo, and now you can safely check in and version `group_vars/<your-username>/vault.yml` without worrying about exposing secrets in cleartext!

!!! tip "Editing ansible-vault files with VSCode"
    If you prefer to edit your vault file using VSCode (*with all its YAML syntax checking*) to nasty-ol' CLI editors, you can set your EDITOR ENV variable by running `export EDITOR="code --wait"`.

## Serving

### Deploy (on autopilot)

To deploy the playbook, run `ansible-playbook -i hosts.your-username deploy.yml`. This will deploy _everything_ on autopilot, including attempting to create VMs using Proxmox, if you've the necessary hosts.

### Deploy (selectively)

To run the playbook selectively (i.e., maybe just deploy traefik), add the name of the role(s) to the `-t` value. This leverages ansible tags to only run tasks which match these tags (*in our case, there's a 1:1 relationship between tags and roles*).

I.e., to deploy only ceph:

```bash
ansible-playbook -i hosts.your-username deploy.yml -t ceph
```

To deploy traefik (overlay), traefikv1, and traefik-forward-auth:

```bash
ansible-playbook -i hosts.your-username deploy.yml -t traefik,traefikv1,traefik-forward-auth
```

### Deploy (semi-autopilot)

Deploying on full autopilot above installs _a lot_ of stuff (and more is being added every day). There's a good chance you don't want everything that is or will be included in the playbook. We've created a special tag that will install the base infrastructure up to a point that you can then choose which recipes to install with the "selective" deploy method described above.

To deploy the base infrastructure:

```bash
ansible-playbook -i hosts.your-username deploy.yml -t infrastructure
```

This will run the playbook up through the `traefik-forward-auth` role and leave you with a fresh "blank canvas" that you can then populate with the recipes of your choosing using the "selective" deploy method.

### Deploy (with debugging)

If something went wrong, append `-vv` to your deploy command, for extra-verbose output :thumbsup:
