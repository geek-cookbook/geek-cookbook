#!/bin/bash
# This script prepares mkdocs for a build (there are some adjustments to be made to the recipes before publishing)

# Fetch git history so that we get last-updated timestamps
git fetch --unshallow

# Append a common footer to all recipes/swarm docs
for i in `find manuscript/ -name "*.md" | grep -v index.md`
do
	# Does this recipe already have a "tip your waiter" section?
	grep -q "Tip your waiter" $i 
	if [ $? -eq 1 ]
	then
		echo -e "\n" >> $i
		cat scripts/recipe-footer.md >> $i 
	else
		echo "WARNING - hard-coded footer exists in $i"
	fi
done

# Now build the docs for publishing
mkdocs build -f mkdocs.yml

# Setup any necessary netlify redirects
cp netlify_redirects.txt site/_redirects