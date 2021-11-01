# Premix Repository

 "Premix" is a private git repository available to [GitHub sponsors](https://github.com/sponsors/funkypenguin), which includes:

 1. Necessary docker-compose and env files for all published recipes
 2. Ansible playbook for deploying the cookbook stack, as well as individual recipes
 3. Helm charts for deploying recipes into Kubernetes

The intention of Premix is that sponsors can launch any recipe with just a `git pull` followed by `ansible-playbook ...` (*Docker Swarm _or_ Kubernetes*), `docker stack deploy ...` (*Docker Swarm*), or `helm install ...` (*Kubernetes*).

## Data Layout

Generally, each recipe with necessary files is contained within its own folder. The intention is that a sponsor could run `git clone git@github.com:funkypenguin/geek-cookbook-premix.git /var/data/config`, and the recipes would be laid out per the [data layout](/reference/data_layout/).
