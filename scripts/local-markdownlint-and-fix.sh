docker run --rm \
    -v "$(pwd):/data:ro" \
    avtodev/markdown-lint:v1 \
    --config /data/.markdownlint.json \
    --ignore /data/_snippets \
    --fix \
    /data/**/*.md


    # --rules /lint/rules/changelog.js \
