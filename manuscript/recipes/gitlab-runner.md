# Gitlab Runner

Some features of GitLab require a "[runner](https://docs.gitlab.com/runner/)" (_in the sense of a "gopher" or a "minion"_). A runner "registers" itself with a GitLab instance, and is given tasks to run. Tasks include running Continuous Integration (CI) builds, and building container images.

While a runner isn't strictly required to use GitLab, if you want to do CI, you'll need at least one. There are many ways to deploy a runner - this recipe focuses on the docker container model.

## Ingredients

!!! summary "Ingredients"
Existing:

    1. [X] [Docker swarm cluster](/ha-docker-swarm/design/) with [persistent shared storage](/ha-docker-swarm/shared-storage-ceph.md)
    2. [X] [Traefik](/ha-docker-swarm/traefik) configured per design
    3. [X] DNS entry for the hostname you intend to use, pointed to your [keepalived](/ha-docker-swarm/keepalived/) IP
    4. [X] [GitLab](/recipes/gitlab) installation (see previous recipe)

## Preparation

### Setup data locations

We'll need several directories to bind-mount into our runner containers, so create them in `/var/data/gitlab`:

```
cd /var/data
mkdir gitlab
cd gitlab
mkdir -p {runners/1,runners/2}
```

### Setup Docker Swarm

Create a docker swarm config file in docker-compose syntax (v3), something like this:

--8<-- "premix-cta.md"

```yaml
version: '3'

services:
  thing1:
    image: gitlab/gitlab-runner
    volumes:
    - /var/data/gitlab/runners/1:/etc/gitlab-runner
    networks:
    - internal

  thing2:
    image: gitlab/gitlab-runner
    volumes:
    - /var/data/gitlab/runners/2:/etc/gitlab-runner
    networks:
    - internal

networks:
  internal:
    driver: overlay
    ipam:
      config:
        - subnet: 172.16.23.0/24
```

### Configure runners

From your GitLab UI, you can retrieve a "token" necessary to register a new runner. To register the runner, you can either create config.toml in each runner's bind-mounted folder (example below), or just `docker exec` into each runner container and execute `gitlab-runner register` to interactively generate config.toml.

Sample runner config.toml:

```
concurrent = 1
check_interval = 0

[[runners]]
  name = "myrunner1"
  url = "https://gitlab.example.com"
  token = "<long string here>"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "ruby:2.1"
    privileged = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
  [runners.cache]
```

## Serving

### Launch runners

Launch the mail server stack by running `docker stack deploy gitlab-runner -c <path -to-docker-compose.yml>`

Log into your new instance at https://**YOUR-FQDN**, with user "root" and the password you specified in gitlab.env.

[^1]: You'll note that I setup 2 runners. One is locked to a single project (_this cookbook build_), and the other is a shared runner. I wanted to ensure that one runner was always available to run CI for this project, even if I'd tied up another runner on something heavy-duty, like a container build. Customize this to your use case.
[^2]: Originally I deployed runners in the same stack as GitLab, but I found that they would frequently fail to start properly when I launched the stack. I think that this was because the runners started so quickly (_and GitLab starts **sooo** slowly!_), that they always started up reporting that the GitLab instance was invalid or unavailable. I had issues with CI builds stuck permanently in a "pending" state, which were only resolved by restarting the runner. Having the runners deployed in a separate stack to GitLab avoids this problem.


--8<-- "recipe-footer.md"