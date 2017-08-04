# How to read this book

## Structure

1. "Recipies" generally follow on from each other. I.e., if a particular recipe requires a mail server, that mail server would have been described in an earlier recipe.
2. Each recipe contains enough detail in a single page to take a project from start to completion.
3. When there are optional add-ons/integrations possible to a project (i.e., the addition of "smart LED bulbs" to Home Assistant), this will be reflected either as a brief "Chef's note" after the recipe, or if they're substantial enough, as a sub-page of the main project

## Conventions

1. When creating swarm networks, we always explicitly set the subnet in the overlay network, to avoid potential conflicts (which docker won't prevent, but which will generate errors) (https://github.com/moby/moby/issues/26912)
