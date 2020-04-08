#!/bin/bash

. ./00_env_pipeline.sh
. ./utils_pipeline.sh

environment=$PIPELINE_ENVIRONMENT
deploymenttstamp=$(date +%s)
echo $environment
if [ "$environment" == "" ];
then
    echo "ERROR you should specify an environemt to deploy too. It should match any of the scripts ./environment_scripts/env_<environment>.sh"
    echo "04_deploy_stack.sh -e <environment>"
    exit -1
fi

images_final_version=$STACK_VERSION
deploy_command="kubectl apply -f"
namespace=$K8S_ENV_NAMESPACE_PREFIX$K8S_NAMESPACE$K8S_ENV_NAMESPACE_POSTFIX
domain=$RESTAPI_K8S_DOMAIN_NAME_PREFIX$RESTAPI_K8S_DOMAIN_NAME$RESTAPI_K8S_DOMAIN_NAME_POSTFIX
spring_profiles_active=$SPRING_PROFILES_ACTIVE
registry_prefix=$DOCKER_REGISTRY_REPOSITORY_PREFIX

echo "DeployStack - Cleaning previous descriptor for $environment"
mkdir -p ../k8s/$environment
rm ../k8s/$environment/*
rc=0;
echo "DeployStack - Building k8s descriptors for environment $environment"
pushd ./stack_definitions/k8s_templates
    ls *.yml | while read fichero;
    do
        if [[ $rc -eq 0 ]] ; then
            echo "DeployStack - Building k8s aplying env  [$fichero]"
            cat ./$fichero |
            sed "s/<k8s_namespace>/$namespace/g" |  
            sed "s/<k8s_restapi_domain>/$domain/g" |                  
            sed "s/<env>/$environment/g" |
            sed "s/<k8s_registry_prefix>/$registry_prefix/g" |            
            sed "s/<spring_profiles_active>/$spring_profiles_active/g" |
            sed "s/<deploymentVersionTag>/$COMMIT_VERSION/g" |
            sed "s/<version>/$images_final_version/g" > ../../../k8s/$environment/$fichero
            rc=$?
        fi
    done
popd
echo "DeployStack - Deploying k8s descriptors for environment $environment"
if [[ $rc -eq 0 ]] ; then
    pushd ../k8s/$environment
        ls *.yml | while read fichero; do
            if [[ $rc -eq 0 ]] ; then
                echo "   deploying ./$fichero"
                echo "$($deploy_command ./$fichero)"
                rc=$?
            else 
                echoerr "   Not deploying $fichero due previous errors"
                exit -1
            fi
        done
    popd
else
    echoerr "   ERROR - Not deploying descriptors"
    exit $rc
fi

if [[ $rc -ne 0 ]] ; then
  echoerr "DeployStack --- Error publishing stack"; exit $rc
fi
