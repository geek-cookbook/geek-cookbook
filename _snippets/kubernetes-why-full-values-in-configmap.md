!!! question "That's a lot of unnecessary text!"
    > Why not just paste in the subset of values I want to change?

    You know what's harder than working out which values from a 2000-line `values.yaml` to change?

    Answer: Working out what values to change when the upstream helm chart has refactored or added options! By pasting in the entirety of the upstream chart, when it comes time to perform upgrades, you can just duplicate your ConfigMap YAML, paste the new values into one of the copies, and compare them side by side to ensure your original values/decisions persist in the new chart.
