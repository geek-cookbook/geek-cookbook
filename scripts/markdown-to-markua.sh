#!/bin/bash

# Markua doesn't know what to do with 4 backticks (````), so convert to 3:
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/\`\`\`\`/\`\`\`/g"

# Can't use relative paths in a book, so make all paths static
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/(\//(https:\/\/geek-cookbook.funkypenguin.co.nz\/)/g"

# strip emojis
for file in `find manuscript -type f -name "*.md" -print0`
do
    tr -cd '\11\12\15\40-\176' < $file > $file-clean
    mv $file-clean $file
done