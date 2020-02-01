#!/usr/bin/env bash

. ./utils_pipeline.sh

export MAVEN_SETTINGS= #You could stablish your maven settings here
export STACK_VERSION=$(mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]')
echo "--------------      stack version ----------------------------------------------"
pwd
echo "--------------------------------------------------------------------------------"
echo "Stack version $STACK_VERSION"