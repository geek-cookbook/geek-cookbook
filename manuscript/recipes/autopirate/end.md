!!! warning
    This is not a complete recipe - it's the conclusion to the [AutoPirate](https://geek-cookbook.funkypenguin.co.nz/recipes/autopirate/) "_uber-recipe_", but has been split into its own page to reduce complexity.

### Launch Autopirate stack

Launch the AutoPirate stack by running ```docker stack deploy autopirate -c <path -to-docker-compose.yml>```

Confirm the container status by running "docker stack ps autopirate", and wait for all containers to enter the "Running" state.

Log into each of your new tools at its respective HTTPS URL. You'll be prompted to authenticate against your OAuth provider, and upon success, redirected to the tool's UI.

## Chef's Notes 

1. This is a complex stack. Sing out in the comments if you found a flaw or need a hand :)