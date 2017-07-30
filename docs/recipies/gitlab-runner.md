### Configure runners (optional)

If you're using runners, you'll need to configure them after completing the UI-based setup of your GitLab instance. You can do this either by creating config.toml in each runner's bind-mounted folder (example below), or by "docker exec'ing" into each runner container and running ```gitlab-container register``` interactively to generate config.toml.

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

1. You'll note that I setup 2 runners. One is locked to a single project (this cookbook build), and the other is a shared runner. No particular reason, I just wanted to get experience with each type. You could easily customize this to your use case.
