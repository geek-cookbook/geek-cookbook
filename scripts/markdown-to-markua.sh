#!/bin/bash

# Markua doesn't know what to do with 4 backticks (````), so convert to 3:
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/\`\`\`\`/\`\`\`/g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/TRTLv2qCKYChMbU5sNkc85hzq2VcGpQidaowbnV2N6LAYrFNebMLepKKPrdif75x5hAizwfc1pX4gi5VsR9WQbjQgYcJm21zec4/https://geek-cookbook.funkypenguin.co.nz/support/"

# Markua doesn't like emojis, so remove them:
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/👏//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/💬//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/👍//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/💰//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/🍷//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/🏢//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/❤️//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/🐢//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/👋//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/🐦//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/📖//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/✉️//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/📺//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/🎥//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/🎵//g"
find manuscript -type f -name "*.md" -print0 | xargs -0 sed -i "s/😁//g"

# Thanks Bencey for this! (Bencey_#8587)





# Do nothing, yet. This is where the sed magic will go
