#!/bin/bash

source env.sh
source functions.sh

ensure_env
ensure_tools

create_main_repo

if [ "$1" = "create" ] || [ "$1" = "pull" ]; then
    all_repos_in_recipe $1
else
    echo "Invalid action: $1"
fi

popd
