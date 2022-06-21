#!/bin/bash

source env.sh

if [ "$mainRepoURL" = "" ] || [ "$mainRepoPath" = "" ] || [ "$recipePath" = "" ]; then
    echo "Invalid arguments. Exiting."
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit 1
fi

if ! command -v yq &> /dev/null
then
    echo "yq could not be found"
    exit 1
fi

if ! command -v git &> /dev/null
then
    echo "git could not be found"
    exit 1
fi

pushd $mainRepoPath

for row in $(cat $recipePath | yq -r '.tasks[] | @base64'); do
    json=$(echo $row | base64 -d)
    action=$(echo $json | jq -r '.action')
    skip=$(echo $json | jq -r '.skip')
    if [ "$skip" = "true" ]; then
        continue
    fi
    if [ "$action" = "waste_time" ]; then
        echo "Wasting Time"
        sleep $(echo $json | jq '.seconds')
    elif [ "$action" = "download_github" ]; then
        subpath=$(echo $json | jq -r '.subpath')
        src=$(echo $json | jq -r '.src')
        dest=$(echo $json | jq -r '.dest')
        if [ "$subpath" != "null" ]; then
            continue
        fi
        ref=$(echo $json | jq -r '.ref')

        re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+?)(\.git)?$"
        if [[ $src =~ $re ]]; then
            repo=${BASH_REMATCH[5]}

            dest=$(echo $dest |  cut -c 3-)
            
            git checkout -b update-subtree main
            git fetch $repo $ref
            git branch "$repo-$ref" "$repo/$ref"
            git merge --squash -s recursive -Xsubtree=$dest -Xtheirs --allow-unrelated-histories --no-commit "$repo-$ref"
            git commit -m "Update subtree $repo"
            git checkout main
            git rebase update-subtree
            git branch -d update-subtree
            git branch -d "$repo-$ref"
            git push origin main
        fi
    fi
done

popd
