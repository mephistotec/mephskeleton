#!/bin/bash
# Writing in error channel
echoerr() { (>&2 echo "$@"); }

function commitStackVersionFile
{
    echo commitStackVersionFile $1
    branch=$(git branch | grep \* | cut -d ' ' -f2-  )
    if [[ "$BRANCH" == "" ]]; then
        BRANCH=$branch
    fi
    remote_branch=$(echo $BRANCH | sed "s/origin\///g")
    branch
    echo "------ Push Command --------"
    echo "---- STATUS ------"
    git status
    echo "---- Current branches ------"
    git branch
    echo "-------- add $1 -------------"
    git add $1
    echo "---------commit ---------------"
    git commit -m "Commiting version file $2"
    command="git push origin $branch:$remote_branch"
    echo $command
    eval $command

}
