#!/usr/bin/env bash

. ./00_env_pipeline.sh

. ./utils_pipeline.sh

function publishImage
{
   pi_REGISTRY_URL=$1
   pi_ORIGINAL_IMAGE=$2
   pi_VERSION=$3

   echo "Publishing imagess - image publication : login at registry if needed"
   loginRegistry

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "Publishing imagess - image publication : Error in access to registry !!!'; exit $rc"
    fi

   echo "Publishing imagess - image publication : pushing to registry [$pi_REGISTRY_URL/$pi_ORIGINAL_IMAGE:$pi_VERSION]"

   command="docker push $pi_REGISTRY_URL/$pi_ORIGINAL_IMAGE:$pi_VERSION"
   echo "Publishing imagess - echo image publication : running $command"
   eval "$command"
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '   image publication : Error in push images!!!'; exit $rc
    fi
   command="docker push $pi_REGISTRY_URL/$pi_ORIGINAL_IMAGE:latest"
   echo "   image publication : running $command"
   eval "$command"
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '   image publication : Error in push images (latest)!!!'; exit $rc
    fi
}

#Building only needed modules
if [ -d "../mephmicro-restapiApp" ]; then
    publishImage $DOCKER_REGISTRY_REPOSITORY_PREFIX$DOCKER_RESTAPI_IMAGE_NAME:$DOCKER_STACK_IMAGE_VERSION
    if [ "$ENTORNO_PIPELINE" == "pre" -o  "$ENTORNO_PIPELINE" == "pro" ]; then
        echo "Push of image without build number $DOCKER_RESTAPI_IMAGE_NAME $STACK_VERSION"
        publishImage $DOCKER_REGISTRY_REPOSITORY_PREFIX$DOCKER_RESTAPI_IMAGE_NAME$STACK_VERSION
    fi

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Error pushing image $DOCKER_RESTAPI_IMAGE_NAME!!!'; exit $rc
    fi
fi;
if [ -d "../mephmicro-engineApp" ]; then
    publishImage $DOCKER_REGISTRY_REPOSITORY_PREFIX $DOCKER_ENGINE_IMAGE_NAME $DOCKER_STACK_IMAGE_VERSION
    if [ "$ENTORNO_PIPELINE" == "pre" -o  "$ENTORNO_PIPELINE" == "pro" ]; then
        echo "Push of image without build number $DOCKER_RESTAPI_IMAGE_NAME $STACK_VERSION"
        publishImage $DOCKER_REGISTRY_REPOSITORY_PREFIX $DOCKER_ENGINE_IMAGE_NAME $STACK_VERSION
    fi
    rc=$?
    . ./environment_scripts/clean_docker_env.sh
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error publicando imagen $DOCKER_ENGINE_IMAGE_NAME!!!'; exit $rc
    fi
fi

#commitStackVersionFile ./stack_definitions/last_build_version.txt $DOCKER_STACK_IMAGE_VERSION
