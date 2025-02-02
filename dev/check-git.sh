#!/bin/bash

# Check if all git repos are committed and pushed.

set -u -o pipefail

root_path=$(readlink -f $(dirname "$0"))

for org_path in "$root_path"/*; do
    if [[ ! -d $org_path ]]; then
        continue
    fi

    for proj_path in "$org_path"/*; do
        if [[ ! -d $proj_path ]]; then
            continue
        fi

        cd $proj_path

        # Check if git repo
        if [[ ! -d .git ]]; then
            continue
        fi

        # Check if dirty
        dirty=$(git status --porcelain=v1 2>/dev/null | wc -l)
        if [[ $dirty != 0 ]]; then
            echo -e "\n""\e[31m""Repo is dirty: ""\e[1m""${proj_path#"$root_path"/}""\e[0m"
            echo -ne "\e[2m"
            git status --porcelain=v1 | head -n5
            echo "..."
            echo -ne "\e[0m"
            continue
        fi

        # Check if up to date with remove (no outstanding pushes only, ignore pulling)
        uptodate=$(git status 2>/dev/null | grep "Your branch is up to date " | wc -l)
        if [[ $uptodate == 0 ]]; then
            echo -e "\n""\e[31m""Repo not pushed: ""\e[1m""${proj_path#"$root_path"/}""\e[0m"
            echo -ne "\e[2m"
            git status 2>/dev/null | grep "Your branch" 
            echo -ne "\e[0m"
            continue
        fi
    done
done
