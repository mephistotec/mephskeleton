#!/usr/bin/env bash

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

pushd ../k8s/$environment
    ls *.yml | while read fichero; do
        kubectl delete -f $fichero
    done
popd
