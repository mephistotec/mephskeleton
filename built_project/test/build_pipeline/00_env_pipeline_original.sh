#!/usr/bin/env bash

## ---------------------------------------------------------
##  Config equipo
## ---------------------------------------------------------

#Collection de destino
export  DOCKER_REGISTRY_REPO=#REGISTRY_DOMAIN_NAME#

## ---------------------------------------------------------
##  CONFIGURACIONES GLOBALES
## ---------------------------------------------------------
export DOCKER_REGISTRY_MNG_BASE_URL=495248209902.dkr.ecr.eu-west-1.amazonaws.com/mango/
export DOCKER_REGISTRY_MNG_REPOSITORY=$DOCKER_REGISTRY_MNG_BASE_URL$DOCKER_REGISTRY_REPO/

export S3_MNG_PRE_BASE_URL=pre-mng-releases/code
export S3_MNG_PRO_BASE_URL=mng-releases/code

#Estas vaiables se aplican en la creacion del proyecto
export K8S_ENV_LIMIT_CPU_ENGINE=1.2
export K8S_ENV_REQUEST_CPU_ENGINE=1
export K8S_LIMIT_MEM_ENGINE=512M
export K8S_REQUEST_MEM_ENGINE=420M
export ENV_JAVA_OPTS_ENGINE="-XX:MaxRAM=384m -Xmx256m -Xms256m"

export K8S_ENV_LIMIT_CPU_FULL=1.2
export K8S_ENV_REQUEST_CPU_FULL=1
export K8S_LIMIT_MEM_FULL=512M
export K8S_REQUEST_MEM_FULL=420M
export ENV_JAVA_OPTS_FULL="-XX:MaxRAM=384m -Xmx256m -Xms256m"

export K8S_ENV_LIMIT_CPU_RESTAPI=1.2
export K8S_ENV_REQUEST_CPU_RESTAPI=1
export K8S_LIMIT_MEM_RESTAPI=512M
export K8S_REQUEST_MEM_RESTAPI=420M
export ENV_JAVA_OPTS_RESTAPI="-XX:MaxRAM=384m -Xmx256m -Xms256m"



. ./utils_pipeline.sh

# Limpiamos config de DOCKER para limpiar de ejecuciones anteriores
unset DOCKER_HOST
unset STACK_VERSION
unset DOCKER_TLS_VERIFY
unset DOCKER_CERT_PATH


#
# Definicion de la version del artrfacto
#
## Extraemos la version del artefacto padre
pushd ..
export ARTIFACT_VERSION=$(mvn help:evaluate -Dexpression=project.version | grep -e '^[^\[]')
export STACK_VERSION=$ARTIFACT_VERSION
echo "La version por defecto es $STACK_VERSION"
popd

export DOCKER_STACK_IMAGE_VERSION=$STACK_VERSION\.$(cat ./stack_definitions/last_build_version.txt)
echo "DOCKER STACK IMAGE VERSION $DOCKER_STACK_IMAGE_VERSION"

#
# Aceptamos -f / --flags para inicializar opciones de generacion definidas en fichero environment_scripts/opt_<opcion>.sh
# Aceptamos -e / --env para inicializar variables en fichero environment_scripts/env_<opcion>.sh
# Aceptamos -v / --verison para seleccionar la versiónque queremos generar
echoerr "PARAMETROS ENV $@"

OPTS=$(getopt "-o f:e: -l flags:env:" -- $@)

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

echoerr "--- Inicializamos opciones y entornos con params $OPTS"

while true; do
  case "$1" in
    -f | --flags )
        echo "Setting flag $2"
        FLAG_PIPELINE=$2;
        option_filename="./environment_scripts/opt_$2.sh";
        if [ ! -f  $option_filename ];
        then
            echoerr "ERROR : No existe $option_filename";
            exit -1;
        fi
        echoerr "====> inicializando opt [$2] --> $option_filename";
        eval ". $option_filename";
        shift;shift ;;

    -v | --version )
        export STACK_VERSION=$2;
        shift;shift ;;
    -e | --env )
        ENTORNO_PIPELINE=$2
        echo "Setting entorno $2"
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done

mkdir -p ./tmp
mkdir -p ./stack_definitions/config_generada
mkdir -p ./tmp/zip_s3_files

echoerr "--- Inicializadas opciones y entornos"

#Nombre del stack
export DOCKER_STACK_NAME=test

#Imagenes
export DOCKER_RESTAPI_IMAGE_NAME=${DOCKER_STACK_NAME}-restapi
export DOCKER_RESTAPI_DOMAIN_NAME=${DOCKER_STACK_NAME}-restapi

#Imagenes
export DOCKER_ENGINE_IMAGE_NAME=${DOCKER_STACK_NAME}-engine
export DOCKER_ENGINE_DOMAIN_NAME=${DOCKER_STACK_NAME}-engine

#Repositorio UCP para la aplicacipn
export DOCKER_REGISTRY_MNG_REPOSITORY=${DOCKER_REGISTRY_MNG_REPOSITORY}


#Aplicamos los flags (se aplican siempre independientemente del entorno)
#aplicaFlag

# Configuracion MAVEN
export MAVEN_SETTINGS="--settings $(pwd)/tools/settings.xml"

#Gestion scripts de integracion
export compose_salida_integracion="last_docker_compose_mock_test_integracion.yml"

echoerr "--- Preparamos el entorno de aceptacion"
echoerr "-----------------------------------"
env | grep DOCKER
echoerr "-----------------------------------"

#Mirasmo si hemos seteado lo que nos jace falta
echo "---------------------------------------------------"
echo "---------------------------------------------------"
echo "------------------  USUARIOS GIT / JENKINS --------"
echo "---------------------------------------------------"
echo "---------------------------------------------------"
echo "[$USER_GIT][$CICD_USER] / reg: [$CICD_REGISTRY_USER]"
echo "---------------------------------------------------"
echo "---------------------------------------------------"
echo "---------------------------------------------------"
