!!! warning
    This is not a complete recipe - it's the conclusion to the [AutoPirate](/recipies/autopirate/start/) "_uber-recipe_", but has been split into its own page to reduce complexity.

### Launch Autopirate stack

Launch the AutoPirate stack by running ```docker stack deploy autopirate -c <path -to-docker-compose.yml>```

Confirm the container status by running "docker stack ps autopirate", and wait for all containers to enter the "Running" state.

Log into each of your new tools at its respective HTTPS URL. You'll be prompted to authenticate against your OAuth provider, and upon success, redirected to the tool's UI.

## Chef's Notes

1. In many cases, tools will integrate with each other. I.e., Radarr needs to talk to SABnzbd and NZBHydra, Ombi needs to talk to Radarr, etc. Since each tool runs within the stack under its own name, just refer to each tool by name (i.e. "radarr"), and docker swarm will resolve the name to the appropriate container. You can identify the tool-specific port by looking at the docker-compose service definition.

## Your comments?
