#!/bin/bash
reponame=$1
projectkey=$2
team=$3
user=$4
password=$5
first_commit=$6

result=$(curl -X POST -s -u $user "https://api.bitbucket.org/2.0/repositories/$team/$reponame" -H "Content-Type: application/json"  -d '{"has_wiki": true, "is_private": true, "project": {"key": "'$projectkey'"}}')
remote_url=$(echo $result | jq -r ".links.clone[0].href")
if [ "" = "$remote_url" ]
then 
    echo "Error creating repo";
    exit -1;
else
    if [ "null" = "$remote_url" ]
    then 
        echo "Error creating repo";
        exit -1;
    fi
fi;

echo "Pushing to repository '$remote_url'"
pushd ..
    git init
    git add .
    git commit -m "$first_commit"
    git remote add origin "$remote_url"
    git remote -v
    git push -u origin master
    git checkout -b develop
    git push --set-upstream origin develop
popd    