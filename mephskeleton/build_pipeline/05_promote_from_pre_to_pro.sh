#!/usr/bin/env bash
#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# STACK_VERSION - Version a desplegar
# DOCKER_REGISTRY_MNG_BASE_URL - URL de registry de PRE (base)
# DOCKER_REGISTRY_MNG_BASE_URL - URL de registry de PRO (base)
# DOCKER_REGISTRY_MNG_USER - Usuario de acceso al registry
# DOCKER_REGISTRY_MNG_PASSWORD - password de acceso al registry
#
#--------------------------------------------------------------------------

. ./00_env_pipeline.sh

echo "Preparado entorno"
#./05_01_pull_push_images.sh $@

#rc=$?
#if [[ $rc -ne 0 ]] ; then
#  echo '--- Error publishing images'; exit $rc
#fi

echo "Desplegando stack"

./04_02_deploy_stack.sh -e pro

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error Desplegando stack'; exit $rc
fi

echo "Deploy complete!!!"