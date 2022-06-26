function ensure_env() {
    if [ "$ORG_NAME" = "" ] || [ "$REPO_NAME" = "" ] || [ "$REPO_PATH" = "" ] || [ "$RECIPE_PATH" = "" ]; then
        echo "Invalid arguments. Exiting."
        exit 1
    fi
}

function ensure_tools() {
    declare -a tools=("jq" "yq" "git" "gh")

    for i in "${tools[@]}"
    do
        if ! command -v $i &> /dev/null
        then
            echo "$i could not be found"
            exit 1
        fi
    done
}

function create_main_repo() {
    repoFull=$ORG_NAME/$REPO_NAME
    gh repo view $repoFull &>/dev/null
    if [ $? -eq 1 ]; then
        # Repo doesn't exist. Create a new one
        echo "Creating a new repo $repoFull"
        gh repo create $repoFull --private

        mkdir -p $REPO_PATH/$repoFull
        pushd $REPO_PATH/$repoFull &>/dev/null
        echo "# Resources" >> README.md
        git init &>/dev/null
        git add README.md
        git commit -m "first commit" &>/dev/null
        git branch -M main
        git remote add origin https://github.com/$repoFull.git
        git push -u origin main &>/dev/null
    else
        echo "Repo already exists. Skipping"
        pushd $REPO_PATH/$repoFull
    fi
    mkdir -p resources
}

function all_repos_in_recipe() {
    script_action=$1
    script_remote=$2
    for row in $(cat $RECIPE_PATH | yq -r '.tasks[] | @base64'); do
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
            ref=$(echo $json | jq -r '.ref')
            if [ "$subpath" != "null" ]; then
                if [ "$script_action" = "create" ]; then
                    temp_path="./tmp/test/"
                    git clone $src $temp_path
                    mv "${temp_path}${subpath}" $dest
                    rm -rf $temp_path
                fi
                continue
            fi

            re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+?)(\.git)?$"
            if [[ $src =~ $re ]]; then    
                repo=${BASH_REMATCH[5]}
                dest=$(echo $dest |  cut -c 3-)
                folder=$(basename $dest | sed 's/[][]//g')

                if [ "$script_action" = "create" ]; then
                    [ -d "$dest" ] && continue
                
                    if [[ ${dest} != *"resources"* ]]; then
                        # A normal clone since its temporary
                        git clone -b $ref $src $dest
                    else
                        gh repo create $ORG_NAME/$folder --private
                        git clone --bare $src
                        cd "${repo}.git"
                        git push --mirror https://github.com/$ORG_NAME/$folder
                        cd ..
                        rm -rf "${repo}.git"
                        cd ..
                        gh repo edit $ORG_NAME/$folder --default-branch $ref
                        git clone https://github.com/$ORG_NAME/$folder
                        cd $folder
                        git remote add upstream $src
                        git remote set-url --push upstream DISABLE
                        cd ../$REPO_NAME
                        git remote add -f $repo https://github.com/$ORG_NAME/$folder
                        git subrepo clone -b $ref $repo $dest
                        git push origin main
                    fi
                elif [ "$script_action" = "pull" ]; then
                    cd ..
                    cd $folder
                    git fetch upstream
                    git pull origin $ref --no-edit
                    #git checkout $ref
                    git merge upstream/$ref --ff-only
                    if [ $? -ne 0 ]; then
                        echo "There are merge conflicts in ${folder}. Please resolve them and run the script again"
                        exit 1
                    fi
                    git push origin $ref

                    cd ../$REPO_NAME
                    git subrepo pull $dest
                    git push origin main
                fi
            fi
        elif [ "$action" = "move_path" ]; then
            if [ "$script_action" = "create" ]; then
                src=$(echo $json | jq -r '.src')
                dest=$(echo $json | jq -r '.dest')
                mv $src $dest
            fi
        elif [ "$action" = "download_file" ]; then
            if [ "$script_action" = "create" ]; then
                path=$(echo $json | jq -r '.path')
                url=$(echo $json | jq -r '.url')
                echo $path
                echo $url
                mkdir -p ${path%/*}
                wget -O $path $url
            fi
        elif [ "$action" = "unzip" ]; then
            if [ "$script_action" = "create" ]; then
                src=$(echo $json | jq -r '.src')
                dest=$(echo $json | jq -r '.dest')
                mkdir -p $dest
                unzip $src -d $dest
            fi
        elif [ "$action" = "remove_path" ]; then
            if [ "$script_action" = "create" ]; then
                path=$(echo $json | jq -r '.path')
                echo "Removing path $path"
                rm -rf $path
                git add .
                git commit -m "Non git stuff"
                git push origin main
            fi
        fi
    done
}
