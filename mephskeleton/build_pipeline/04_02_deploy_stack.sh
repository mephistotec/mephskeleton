#!/usr/bin/env bash

#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# DOCKER_STACK_VERSION - Version a desplegar - si no se define -v <version> , la del POM
# DOCKER_REGISTRY_MNG_REPOSITORY - Repositorio al que subir las imagenes, se define con el -f <registrymng_pre> por ejemplo
# DOCKER_REGISTRY_MNG_USER - Usuario de acceso al registry
# DOCKER_REGISTRY_MNG_PASSWORD - password de acceso al registry
#
# necesita $ADDITIONAL_COMPOSES que se define en funcion de aplicaEntorno que se llame
#
# necesita de que se defina con -e <entorno> el entorno para el que se publican imagenes.
#--------------------------------------------------------------------------


. ./00_env_pipeline.sh

. ./utils_pipeline.sh

echo "------- antes de lanzar comando ------------"
env | grep AWS
echo "--------------------------------------------"


#assumeK8Srole

entorno=$ENTORNO_PIPELINE
deploymenttstamp=$(date +%s)
echo $entorno
if [ "$entorno" == "" ];
then
    echo "ERROR falta entorno, se ha de especificar un entorno y se pueden especificar flags para inicializar registro a usar"
    echo "Uos 04_deploy_stack.sh <entorno> <flag de registry>"
    exit -1
fi

images_final_version=$DOCKER_STACK_IMAGE_VERSION
#if [ "$entorno" == "pro" ]; then
#    images_final_version=$DOCKER_STACK_VERSION
#fi


aplicaEntorno $ENTORNO_PIPELINE

deploy_command="$(pwd)/tools/kravd/binaries/kravd"

function prepareDeployCommand
{
##    wget https://s3-eu-west-1.amazonaws.com/appbucket-appbucket-17dk9hqwmrgrc/kravd/client/kravd-linux-amd64_1.0.3 -O ./tools/kravd/bin/kravd && chmod 775 ./tools/kravd/bin/*
    #export deploy_command=$(pwd)/tools/kravd/bin/kravd
    chmod +x $(pwd)/tools/kravd/kravd.sh
    case "$(uname -s)" in
       Darwin)
         echo 'Deploy macos'
            ## Bajamos versión de kravtd
            pushd $(pwd)/tools/kravd/
                docker build --tag  kravd_docker .
            popd


            deploy_command=". $(pwd)/tools/kravd/kravd.sh"
            rc=$?
         ;;
       *)
         echo 'deploy linux'
         deploy_command=$(pwd)/kravd.sh
         rc=$?
         ;;
    esac
}


function deployDescriptor
{
    # Stage from parameters
    environment=$K8S_DESCRIPTORS_ENV
    # File
    file=$1
    folder=$2

    echo "Deply command ($deploy_command  $file $K8S_DESCRIPTORS_ENV)"

    # Use kravd client to deploy
    $deploy_command  $file $K8S_DESCRIPTORS_ENV $(pwd)
    rc=$?
}

if [[ "$ONLY_DESCRIPTORS" != "yes" ]] ; then
    prepareDeployCommand
fi


if [[ $rc -ne 0 ]] ; then
  echo "--- Error publicando STACK $DOCKER_STACK_NAME - preparando deploy command!!!"; exit $rc
fi

pushd ./stack_definitions/
    echo "DeployStack - Building k8s"
    mkdir -p k8s/$K8S_DESCRIPTORS_ENV
    rm k8s/$K8S_DESCRIPTORS_ENV/*
    k8sTemplatesFolder="../../infrastructure/k8s"
    ls $k8sTemplatesFolder | while read fichero;
    do
        echo "DeployStack - Building k8s aplying env  [k8s/$fichero]"
        cat $k8sTemplatesFolder/$fichero |
          sed "s/<limit_cpu_value_restapi>/$K8S_ENV_LIMIT_CPU_RESTAPI/g" |
          sed "s/<limit_cpu_value_engine>/$K8S_ENV_LIMIT_CPU_ENGINE/g" |
          sed "s/<limit_cpu_value_full>/$K8S_ENV_LIMIT_CPU_FULL/g" |
          sed "s/<limit_memory_value_restapi>/$K8S_LIMIT_MEM_RESTAPI/g" |
          sed "s/<limit_memory_value_engine>/$K8S_LIMIT_MEM_ENGINE/g" |
          sed "s/<limit_memory_value_full>/$K8S_LIMIT_MEM_FULL/g" |
          sed "s/<request_cpu_value_restapi>/$K8S_ENV_REQUEST_CPU_RESTAPI/g" |
          sed "s/<request_cpu_value_engine>/$K8S_ENV_REQUEST_CPU_ENGINE/g" |
          sed "s/<request_cpu_value_full>/$K8S_ENV_REQUEST_CPU_FULL/g" |
          sed "s/<request_memory_value_restapi>/$K8S_REQUEST_MEM_RESTAPI/g" |
          sed "s/<request_memory_value_engine>/$K8S_REQUEST_MEM_ENGINE/g" |
          sed "s/<request_memory_value_full>/$K8S_REQUEST_MEM_FULL/g" |
          sed "s/<env_java_opts_restapi>/$ENV_JAVA_OPTS_RESTAPI/g" |
          sed "s/<env_java_opts_engine>/$ENV_JAVA_OPTS_ENGINE/g" |
          sed "s/<env_java_opts_full>/$ENV_JAVA_OPTS_FULL/g" |
          sed "s/<env>/$K8S_DESCRIPTORS_ENV/g" |
#          sed "s/<DEPLOYMENT_TSTAMP_VALUE>/$deploymenttstamp/g" |
          sed "s/<env_app>/$ENTORNO_PIPELINE/g" |
          sed "s/<version>/$images_final_version/g"  |
          sed "s/<pick-one-alb-endpoint>/$K8S_ELB/g"> k8s/$fichero
    done
    rc=$?
    echo "ONLY DESCRIPTORS : $ONLY_DESCRIPTORS"
    if [[ "$ONLY_DESCRIPTORS" != "yes" ]] ; then
        pushd k8s
            ls *deployment*.yml | while read fichero; do
                echo "deploying descriptors ... $fichero"
                echo "------- antes de lanzar comando ------------"
                env | grep AWS
                echo "--------------------------------------------"
                deployDescriptor $fichero $(pwd)/../..
            done
        popd
    else
        echo "Not deploying descriptors"
    fi
popd

#export AWS_ACCESS_KEY_ID=$OLD_AWS_ACCESS_KEY_ID
#export AWS_SECRET_ACCESS_KEY=$OLD_AWS_SECRET_ACCESS_KEY
#export AWS_SESSION_TOKEN=$OLD_AWS_SESSION_TOKEN

. ./environment_scripts/clean_docker_env.sh

if [[ $rc -ne 0 ]] ; then
  echo "--- Error publicando STACK $DOCKER_STACK_NAME!!!"; exit $rc
fi
