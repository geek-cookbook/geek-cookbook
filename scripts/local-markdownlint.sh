docker run --rm \
    -v "$(pwd):/data:ro" \
    avtodev/markdown-lint:v1 \
    --config /data/.markdownlint.yaml \
    --ignore /data/_snippets \
    /data/**/*.md


    # --rules /lint/rules/changelog.js \
