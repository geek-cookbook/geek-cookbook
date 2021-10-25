<!-- Provide a general summary of your changes in the Title above ^^^ -->

## Description
<!--- Describe your changes in detail -->

## Motivation and Context
<!--- Why is this change required? What problem does it solve? -->
<!--- If it fixes an open issue, please link to the issue here. -->

## How Has This Been Tested?
<!--- Please describe in detail how you tested your changes. -->

## Screenshots (if appropriate):

## Types of changes
<!--- What types of changes does your code introduce? Put an `x` in all the boxes that apply: -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)

## Checklist
<!--- Go over all the following points, and put an `x` in all the boxes that apply. -->
<!--- If you're unsure about any of these, don't hesitate to ask. We're here to help! -->

- [ ] I have read the [contribution guide](https://geek-cookbook.funkypenguin.co.nz/community/contribute/#contributing-recipes)
- [ ] The format of my changes matches that of other recipes (*ideally it was copied from [template](/manuscript/recipes/template.md)*)
- [ ] My changes have passed markdown linting, either by running `./scripts/local-markdownlint.sh` locally, or by checking the status of the PR check below.

<!-- 
delete these next checks if not adding a new recipe 
-->
- [ ] I've added at least one footnote to my recipe (*Chef's Notes*)
- [ ] I've updated `common_links.md` in the `_snippets` directory and sorted alphabetically
- [ ] I've updated the navigation in `mkdocs.yaml` in alphabetical order
- [ ] I've updated `CHANGELOG.md` in reverse chronological order order
- [ ] I'm using the [oldest-possible version](https://docs.docker.com/compose/compose-file/compose-versioning/#version-3) of Docker-compose syntax for the feature my recipe needs (*v3.2 unless there's a specific need for a later version*)
- [ ] If traefik integration is required, I've included both v1 and v2 labels (*see [template](/manuscript/recipes/template.md)*)
- [ ] If a recipe-specific overlay network is required, I've used a unique subnet and recorded it in [networks.md](manuscript/reference/networks.md)
- [ ] I've considered updating `.github/CODEOWNERS` so that I'll be automatically included as a reviewer on future changes to this recipe