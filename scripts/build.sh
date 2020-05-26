#!/bin/bash
# This script prepares mkdocs for a build (there are some adjustments to be made to the recipes before publishing)

# Copy the contents of "manuscript" to a new "publish" folder
# mkdir -p publish
# mkdir -p publish/overrides
# cp -pr {manuscript,overrides} publish/ 
# cp mkdocs.yml publish/

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

# Fetch git history so that we get last-updated timestamps
git fetch --unshallow

# Now build the docs for publishing
# mkdocs build -f publish/mkdocs.yml
mkdocs build


# Setup any necessary netlify redirects
# cp netlify_redirects.txt publish/site/_redirects
cp netlify_redirects.txt site/_redirects
