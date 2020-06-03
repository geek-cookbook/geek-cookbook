#!/bin/bash

for file in `find manuscript -type f -name "*.md"`
do
    echo "Processing $file..."

    # Markua doesn't know what to do with 4 backticks (````), so convert to 3:
    sed -i "s/\`\`\`\`/\`\`\`/g" $file

    # Can't use relative paths in a book, so make all paths static
    sed -i 's/(\//(https:\/\/geek-cookbook.funkypenguin.co.nz\/)/g' $file

    # strip emojis
    tr -cd '\11\12\15\40-\176' < $file > $file-clean
    mv $file-clean $file
done