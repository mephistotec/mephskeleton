#!/usr/bin/env bash
. ./utils_pipeline.sh



pushd ..
export MAVEN_SETTINGS= #CUSTOM_USER_VALUE : You could stablish your maven settings here
export STACK_VERSION=$(mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]')
echo "Stack version $STACK_VERSION"
popd

#Stack name
export DOCKER_STACK_NAME=mephmicro

#Images
export DOCKER_RESTAPI_FWK_IMAGE_NAME=${DOCKER_STACK_NAME}-restapi-framework
export DOCKER_RESTAPI_IMAGE_NAME=${DOCKER_STACK_NAME}-restapi

#Images
export DOCKER_ENGINE_FWK_IMAGE_NAME=${DOCKER_STACK_NAME}-engine-framework
export DOCKER_ENGINE_IMAGE_NAME=${DOCKER_STACK_NAME}-engine

#Default k8s descriptors values (you can set specific environment values en the env_<environment>.sh script)
export K8S_NAMESPACE=meph
export K8S_ENV_NAMESPACE_PREFIX=
export K8S_ENV_NAMESPACE_POSTFIX=

#Default k8s descriptors values (you can set specific environment values en the env_<environment>.sh script)
export RESTAPI_K8S_DOMAIN_NAME=meph.local
export RESTAPI_K8S_DOMAIN_NAME_PREFIX=mephmicro.
export RESTAPI_K8S_DOMAIN_NAME_POSTFIX=


#Timestamp
export STACK_TIMESTAMP=$(date +%s)

## ---------------------  REGISTRY ---------------------
#Registry 
#CUSTOM_USER_VALUE : here you can set your registry domain name value
export DOCKER_REGISTRY_REPOSITORY_PREFIX=localhost:5000

IMAGE_PREFIX=""
if [ "" != "$DOCKER_REGISTRY_REPOSITORY_PREFIX" ] ; then
  IMAGE_PREFIX="$DOCKER_REGISTRY_REPOSITORY_PREFIX/";
  echo "Building image - Our image prefix will be $IMAGE_PREFIX";
fi  

#Registry login
#CUSTOM_USER_VALUE : here you coul set your login registry method
function loginRegistry
{
    echo "Login to registry: default behaivour, don't need to login ;)";
}

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
        env_filename="./environment_scripts/env_$2.sh";
        if [ ! -f  $env_filename ];
        then
            echoerr "ERROR : It does not exist $env_filename";
            exit -1;
        fi
        echo "Running environment file $env_filename"
        eval ". $env_filename";
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done

## ---------------------  CONFIGURATIOIN MANAGEMENT ---------------------

#Definition of active profiles for spring framework if nneded
export SPRING_PROFILES_ACTIVE=$PIPELINE_ENVIRONMENT
