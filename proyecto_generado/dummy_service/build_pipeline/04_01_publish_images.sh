#!/usr/bin/env bash

#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# DOCKER_STACK_VERSION - Version a desplegar - si no se define -v <version> , la del POM
# DOCKER_REGISTRY_MNG_REPOSITORY - Repositorio al que subir las imagenes, se define con el -f <registrymng_pre> por ejemplo
# DOCKER_REGISTRY_MNG_USER - Usuario de acceso al registry
# DOCKER_REGISTRY_MNG_PASSWORD - password de acceso al registry
#
# necesita de que se defina con -e <entorno> el entorno para el que se publican imagenes.
#--------------------------------------------------------------------------

. ./00_env_pipeline.sh

. ./utils_pipeline.sh

#if [ "$flagExec" == "" ];
#then
#    echo "ERROR falta flag , se ha de especificar un entorno y se pueden especificar flags para inicializar registro a usar"
#    echo "Uos 04_deploy_stack.sh <entorno> <flag de registry>"
#    exit -1
#fi

#echo "Inicializamos build con opts $entorno $flagExec"
#. ./00_env_pipeline.sh -f $flagExec -e $entorno

function publishImage
{
   pi_REGISTRY_URL=$1
   pi_ORIGINAL_IMAGE=$2
   pi_VERSION=$3

   echo "--- Generando tag $pi_ORIGINAL_IMAGE:$pi_VERSION $pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:$pi_VERSION"

   docker tag $pi_ORIGINAL_IMAGE:$pi_VERSION $pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:$pi_VERSION

   echo "--- Generando tag  $pi_ORIGINAL_IMAGE:$pi_VERSION $pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:latest"
   docker tag $pi_ORIGINAL_IMAGE:$pi_VERSION $pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:latest

   echo "--- Login a registry "
   loginRegistry
   assumeK8Srole

   echo "--- Tenemos role $AWS_ACCESS_KEY_ID $AWS_SESSION_TOKEN"

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error accediendo a registry!!!'; exit $rc
    fi

   echo "--- push registry [$pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:$pi_VERSION] [$pi_USER] [******]"

   command="docker push $pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:$pi_VERSION"
   echo "--- Lanzamos $command"
   eval "$command"
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error push images!!!'; exit $rc
    fi
   command="docker push $pi_REGISTRY_URL$pi_ORIGINAL_IMAGE:latest"
   echo "--- Lanzamos $command"
   eval "$command"
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error push images!!!'; exit $rc
    fi
}

. ./environment_scripts/clean_docker_env.sh

#Cogemos los composes relevantes
if [ -d "../dummy_service-restapiApp" ]; then
    #Publicamos las imagenes de los dos artefactos
    publishImage $DOCKER_REGISTRY_URL $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_STACK_IMAGE_VERSION
    if [ "$ENTORNO_PIPELINE" == "pre" -o  "$ENTORNO_PIPELINE" == "pro" ]; then
        echo "Push de imagen sin buildnumber $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_STACK_VERSION"
        publishImage $DOCKER_REGISTRY_URL $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_STACK_VERSION
    fi

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error publicando imagen $DOCKER_RESTAPI_IMAGE_NAME!!!'; exit $rc
    fi
fi;
if [ -d "../dummy_service-engineApp" ]; then
    publishImage $DOCKER_REGISTRY_MNG_REPOSITORY $DOCKER_ENGINE_IMAGE_NAME $DOCKER_STACK_IMAGE_VERSION
    if [ "$ENTORNO_PIPELINE" == "pre" -o  "$ENTORNO_PIPELINE" == "pro" ]; then
        echo "Push de imagen sin buildnumber $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_STACK_VERSION"
        publishImage $DOCKER_REGISTRY_MNG_REPOSITORY $DOCKER_ENGINE_IMAGE_NAME $DOCKER_STACK_VERSION
    fi
    rc=$?
    . ./environment_scripts/clean_docker_env.sh
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error publicando imagen $DOCKER_ENGINE_IMAGE_NAME!!!'; exit $rc
    fi
fi
if [ -d "../dummy_service-singleApp" ]; then
    publishImage $DOCKER_REGISTRY_MNG_REPOSITORY $DOCKER_SINGLEAPP_IMAGE_NAME $DOCKER_STACK_IMAGE_VERSION
    if [ "$ENTORNO_PIPELINE" == "pre" -o  "$ENTORNO_PIPELINE" == "pro" ]; then
        echo "Push de imagen sin buildnumber $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_STACK_VERSION"
        publishImage $DOCKER_REGISTRY_MNG_REPOSITORY $DOCKER_SINGLEAPP_IMAGE_NAME $DOCKER_S$DOCKER_STACK_VERSION
    fi
    rc=$?
    . ./environment_scripts/clean_docker_env.sh
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error publicando imagen $DOCKER_SINGLEAPP_IMAGE_NAME!!!'; exit $rc
    fi
fi

commitStackVersionFile ./stack_definitions/last_build_version.txt $DOCKER_STACK_IMAGE_VERSION
