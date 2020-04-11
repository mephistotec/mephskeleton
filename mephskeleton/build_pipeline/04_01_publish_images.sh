#!/bin/bash
. ./00_env_pipeline.sh

. ./utils_pipeline.sh

function publishImage
{
   IMAGE_TO_PUSH=$1

   echo "Publishing images - image publication : login at registry if needed"
   loginRegistry

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "Publishing images - image publication : Error in access to registry !!!'; exit $rc"
    fi

   echo "Publishing images - image publication : pushing to registry [$pi_REGISTRY_URL/$pi_ORIGINAL_IMAGE:$pi_VERSION]"

   command="docker push $IMAGE_TO_PUSH"
   echo "Publishing images - echo image publication : running $command"
   eval "$command"
   rc=$?
   if [[ $rc -ne 0 ]] ; then
      echo 'Publishing images - image publication : Error in push images!!!'; exit $rc
   fi
}

#Building only needed modules
if [ -d "../mephskeleton-restapiApp" ]; then
    pushd ../mephskeleton-restapiApp
      calculate_framework_version
    popd
    publishImage $DOCKER_RESTAPI_FWK_IMAGE_NAME:$FRAMEWORK_VERSION
    publishImage $DOCKER_RESTAPI_IMAGE_NAME:$STACK_VERSION
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Error pushing image $DOCKER_RESTAPI_IMAGE_NAME!!!'; exit $rc
    fi
fi;
if [ -d "../mephskeleton-engineApp" ]; then
    pushd ../mephskeleton-engineApp
      calculate_framework_version
    popd
    publishImage $DOCKER_ENGINE_FWK_IMAGE_NAME:$FRAMEWORK_VERSION
    publishImage $DOCKER_ENGINE_IMAGE_NAME:$STACK_VERSION
    rc=$?
    . ./environment_scripts/clean_docker_env.sh
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error publicando imagen $DOCKER_ENGINE_IMAGE_NAME!!!'; exit $rc
    fi
fi
