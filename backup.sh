#!/bin/bash
set -e

BASEPATH="$(jq -r '.base' config.json)"

sync() {
  # stdin: path url
  # args: dir
  while IFS= read -r line; do
    path="$BASEPATH/$1/$(echo "$line" | cut -d " " -f 1)"
    url=$(echo "$line" | cut -d " " -f 2)
    if [ -d "$path" ]; then
      pushd "$path"
      git fetch
      popd
    else
      mkdir -p "$path"
      pushd "$path"
      git clone --mirror "$url" .
      popd
    fi
  done
}

# github.com
gh api -XGET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -F affiliation=owner --paginate /user/repos --jq '.[] | .full_name + " " + .html_url' | sync github.com

jq -r '.orgs[]' config.json | while IFS= read -r org; do
  gh api -XGET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -F affiliation=owner --paginate "/orgs/$org/repos" --jq '.[] | .full_name + " " + .html_url' | sync github.com
done

# gist
gh api -XGET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" -F affiliation=owner --paginate /gists --jq '.[] | .owner.login + "/" + .id + " " + .git_pull_url' | sync gist.github.com
