#!/bin/sh

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_website_files() {
  git checkout -b leanpub-preview
  git add manuscript 
  git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
  #git remote add origin-leanpub-preview https://${LEANPUB-PREVIEW-TOKEN}@github.com/funkypenguin/geek-cookbook.git > /dev/null 2>&1
  #git remote add origin-leanpub-preview https://${TOKEN}@github.com/funkypenguin/geek-cookbook.git
  #git push --quiet --set-upstream origin-leanpub-preview leanpub-preview 
  git push --quiet --set-upstream origin leanpub-preview 
}

setup_git
commit_website_files
upload_files
