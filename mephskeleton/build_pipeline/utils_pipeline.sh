#!/bin/bash
NEED_TO_BUILD=false
lastImageExists=false

# Writing in error channel
echoerr() { (>&2 echo "$@"); }

log()
{
    ( >&2 echo "$@");
}

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


function existImage
{
    lastImageExists=false;
    localId=$(docker image ls -q $1);
    if [ -z "$localId"];
    then
        repository=$(echo "$1" | cut -d"/" -f2 | cut -d":" -f1);
        version=$(echo "$1" | cut -d"/" -f2 | cut -d":" -f2);
        echo $(curl -s "$DOCKER_REGISTRY_REPOSITORY/v2/$repository/tags/list")
        numImages=$(curl -s "$DOCKER_REGISTRY_REPOSITORY/v2/$repository/tags/list" | grep $version | wc -l);
        echo "Asking to repo $DOCKER_REGISTRY_REPOSITORY/v2/$repository/tags/list and $version, $numImages exists"
        if [[ $numImages -ge 1 ]];
        then
            lastImageExists=true;
            echo "Image $1 exists in repo";
        fi
    else
        echo "Image $1 exists locally"
        lastImageExists=true;
    fi
}

function is_needed_to_build
{
    NEED_TO_BUILD=false;
    if [[ "$RUNNING_PIPELINE" == "true" ]];
    then
        if [ -d "../mephskeleton-restapiApp" ]; then
            existImage $DOCKER_RESTAPI_IMAGE_NAME:$STACK_VERSION 
            if [[ "$lastImageExists" == "false" ]];
            then
                echo "Restapi needs to be built"
                NEED_TO_BUILD=true
            fi
        fi;
        #if still empty
        if [[ "false" == "$NEED_TO_BUILD" ]];
        then
            if [ -d "../mephskeleton-engineApp" ]; then
                existImage $DOCKER_ENGINE_IMAGE_NAME:$STACK_VERSION
                if [[ "$lastImageExists" == "false" ]];
                then
                    echo "Engine needs to be built"
                    NEED_TO_BUILD=true
                fi
            fi
        fi
    else
        echo "Need to build, not in pipeline"
        NEED_TO_BUILD=true
    fi
}


function calculate_framework_version
{
  FRAMEWORK_VERSION=$(mvn dependency:tree | grep ":" | grep -v mephskeleton  | grep -v Total | grep -v Finish | md5)
  if [[ "$FRAMEWORK_VERSION" == "" ]] ; then
    echo "Building image - cannot use hash, looking for simulation of hash ..."
    NUM_DEPENDENCIES=$(mvn dependency:tree | grep ":" | grep -v mephskeleton  | grep -v Total | grep -v Finish | wc -l)
    DEP_SIZE=$(mvn dependency:tree | grep ":" | grep -v mephskeleton  | grep -v Total | grep -v Finish | wc -c)
    FRAMEWORK_VERSION=$(echo "$NUM_DEPENDENCIES$DEP_SIZE" | xargs | sed 's/ //g')
  fi
  echo "Building image - calculated framework version as $FRAMEWORK_VERSION"
}