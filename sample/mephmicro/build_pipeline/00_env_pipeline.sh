#!/usr/bin/env bash
. ./utils_pipeline.sh

## ---------------------  OPTIONS MANAGEMENT ---------------------

#Manage modifier for the pipeline commands
OPTS=$(getopt "-o f:e: -l flags:env:" -- $@)
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"
echoerr "Evaluating options $OPTS"

while true; do
  case "$1" in
    -e | --env )
        PIPELINE_ENVIRONMENT=$2
        echo "Processing environment flags $2"
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done

## ---------------------  CONFIGURATIOIN MANAGEMENT ---------------------

export MAVEN_SETTINGS= #CUSTOM_USER_VALUE : You could stablish your maven settings here
export STACK_VERSION=$(mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]')
echo "Stack version $STACK_VERSION"

#Stack version with buildnumber for docker images
export DOCKER_STACK_IMAGE_VERSION=$STACK_VERSION\.$(cat ./stack_definitions/last_build_version.txt)
echo "Docker image Stack version $DOCKER_STACK_IMAGE_VERSION"

#Stack name
export DOCKER_STACK_NAME=mephmicro

#Images
export DOCKER_RESTAPI_IMAGE_NAME=${DOCKER_STACK_NAME}-restapi

#Images
export DOCKER_ENGINE_IMAGE_NAME=${DOCKER_STACK_NAME}-engine

#Default k8s descriptors values (you can set specific environment values en the env_<environment>.sh script)
export K8S_NAMESPACE=meph
export K8S_ENV_NAMESPACE_PREFIX=
export K8S_ENV_NAMESPACE_POSTFIX=

#Default k8s descriptors values (you can set specific environment values en the env_<environment>.sh script)
export RESTAPI_K8S_DOMAIN_NAME=meph.com
export RESTAPI_K8S_DOMAIN_NAME_PREFIX=mephmicro.
export RESTAPI_K8S_DOMAIN_NAME_POSTFIX=

#Definition of active profiles for spring framework if nneded
export SPRING_PROFILES_ACTIVE=$PIPELINE_ENVIRONMENT

## ---------------------  REGISTRY ---------------------
#Registry 
#CUSTOM_USER_VALUE : here you can set your registry domain name value
export DOCKER_REGISTRY_REPOSITORY_PREFIX=localhost:5000

#Registry login
#CUSTOM_USER_VALUE : here you coul set your login registry method
function loginRegistry
{
    echo "Login to registry: default behaivour, don't need to login ;)";
}

