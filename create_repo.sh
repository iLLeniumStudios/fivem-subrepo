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

[ ! -d "$mainRepoPath/resources" ] && git clone $mainRepoURL $mainRepoPath

pushd $mainRepoPath

mkdir -p resources

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
            temp_path="./tmp/test/"
            git clone $src $temp_path
            mv "${temp_path}${subpath}" $dest
            rm -rf $temp_path
            continue
        fi
        ref=$(echo $json | jq -r '.ref')

        re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+?)(\.git)?$"
        if [[ $src =~ $re ]]; then    
            repo=${BASH_REMATCH[5]}

            dest=$(echo $dest |  cut -c 3-)
            
            [ -d "$dest" ] && continue
            
            if [[ ${dest} != *"resources"* ]]; then
                # A normal clone since its temporary
                git clone -b $ref $src $dest
            else
                git remote add -f $repo $src
                git subtree add --prefix $dest --squash $repo $ref -m "Add $repo as subtree"
                git merge --squash --allow-unrelated-histories main
                git push origin main
            fi
        fi
    elif [ "$action" = "move_path" ]; then
        src=$(echo $json | jq -r '.src')
        dest=$(echo $json | jq -r '.dest')
        mv $src $dest
    elif [ "$action" = "download_file" ]; then
        path=$(echo $json | jq -r '.path')
        url=$(echo $json | jq -r '.url')
        echo $path
        echo $url
        mkdir -p ${path%/*}
        wget -O $path $url
    elif [ "$action" = "unzip" ]; then
        src=$(echo $json | jq -r '.src')
        dest=$(echo $json | jq -r '.dest')
        mkdir -p $dest
        unzip $src -d $dest
    elif [ "$action" = "remove_path" ]; then
        path=$(echo $json | jq -r '.path')
        echo "Removing path $path"
        rm -rf $path
        git add .
        git commit -m "Non git stuff"
        git push origin main
    fi
done

popd
