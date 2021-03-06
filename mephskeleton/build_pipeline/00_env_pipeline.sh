#!/bin/bash
. ./utils_pipeline.sh

pushd ..
export MAVEN_SETTINGS= #CUSTOM_USER_VALUE : You could stablish your maven settings here
export STACK_VERSION=$(git rev-parse --short HEAD)
export CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
popd

#Stack name
export DOCKER_STACK_NAME=mephskeleton

#k8S
export K8S_NAMESPACE=meph
export K8S_ENV_NAMESPACE_PREFIX=
export K8S_ENV_NAMESPACE_POSTFIX=

#K8s domain values
export RESTAPI_K8S_DOMAIN_NAME=meph.com
export RESTAPI_K8S_DOMAIN_NAME_PREFIX=mephskeleton.
export RESTAPI_K8S_DOMAIN_NAME_POSTFIX=


## ---------------------  REGISTRY ---------------------
#Registry 
#CUSTOM_USER_VALUE : here you can set your registry domain name value
export DOCKER_REGISTRY_REPOSITORY_PREFIX=#REGISTRY_DOMAIN_NAME#
export DOCKER_REGISTRY_REPOSITORY=#REGISTRY_URL#

#Registry login
#CUSTOM_USER_VALUE : here you coul set your login registry method
function loginRegistry
{
    echo "Login to registry: default behaivour, don't need to login ;)";
}

IMAGE_PREFIX=""
if [ "" != "$DOCKER_REGISTRY_REPOSITORY_PREFIX" ] ; then
  IMAGE_PREFIX="$DOCKER_REGISTRY_REPOSITORY_PREFIX/";
  echo "Building image - Our image prefix will be $IMAGE_PREFIX";
fi  

## CUSTOM_USER_VALUES: you cna set your sonar acces here or inject it from the pipeline you are runnin
## SONAR
#export SONAR_USER=admin
#export SONAR_PASSWORD=admin
#export SONAR_HOST_URL=http://sonar-ip-service

export SONAR_GOAL="sonar:sonar"
if [ "$SONAR_PASSWORD" == "" ];
then
    export SONAR_PARAMS="-Dsonar.login=$SONAR_USER -Dsonar.host.url=$SONAR_HOST_URL"
else
    export SONAR_PARAMS="-Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASSWORD -Dsonar.host.url=$SONAR_HOST_URL"
fi



#Images
export DOCKER_RESTAPI_FWK_IMAGE_NAME=${IMAGE_PREFIX}${DOCKER_STACK_NAME}-restapi-framework
export DOCKER_RESTAPI_IMAGE_NAME=${IMAGE_PREFIX}${DOCKER_STACK_NAME}-restapi

#Images
export DOCKER_ENGINE_FWK_IMAGE_NAME=${IMAGE_PREFIX}${DOCKER_STACK_NAME}-engine-framework
export DOCKER_ENGINE_IMAGE_NAME=${IMAGE_PREFIX}${DOCKER_STACK_NAME}-engine



## By default , not in pipeline
RUNNING_PIPELINE=false

## ---------------------  OPTIONS MANAGEMENT ---------------------

echo "Processing options : $@"

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
    -f | --opt )
            echo "Processing option flags $2"
            env_filename="./environment_scripts/opt_$2.sh";
            if [ ! -f  $env_filename ];
            then
                echoerr "ERROR : It does not exist $env_filename";
                exit -1;
            fi

            if [[ "$2" == "jenkins" ]];
            then
                RUNNING_PIPELINE=true;
            fi

            echo "Running opt file $env_filename"
            eval ". $env_filename";
            shift;shift ;;        
    -- ) shift ;;
    * ) break ;;
  esac
done

## ---------------------  CONFIGURATIOIN MANAGEMENT ---------------------

#Definition of active profiles for spring framework if nneded
export SPRING_PROFILES_ACTIVE=$PIPELINE_ENVIRONMENT

## --------------------- determine if build is needed ---------------------
echo "Running in pipeline $RUNNING_PIPELINE"