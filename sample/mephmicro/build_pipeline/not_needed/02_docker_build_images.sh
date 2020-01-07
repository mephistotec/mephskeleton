#!/usr/bin/env bash

#
# En el script de entonro 00_env_pipeline se definen las variables
#
# DOCKER_RESTAPI_IMAGE_NAME  -- Nombre de la IMAGEN para la aplicacion REST
# DOCKER_ENGINE_IMAGE_NAME  -- Nombre de la imagen del ENGINE
#

#Inicializamos el entorno sin necesitar parametros adicionales pues los jar estan generados
. ./00_env_pipeline.sh



basePath=$(pwd)

#Nos locagamos en el registry de CAPSIDE para poder acceder a las imagenes
loginRegistry

function build_image_for_java
{
    ## Esperamos como argumentos el directorio del artefacto (proyecto) y el nombre de la imagen
    pushd ../$1

    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')

    popd

    BASEDOCKERDIR=./docker_images_definitions/java

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar
    cp ../$1/target/$ARTIFACT.jar $BASEDOCKERDIR/tmp_for_jars/
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Bulild IMAGE ERROR error : '; exit $rc
    fi

    echo "Hemos copiado binarios para $1, $ARTIFACT --> $2:($DOCKER_STACK_IMAGE_VERSION)"

    pushd $BASEDOCKERDIR

    pwd
    ls ./tmp_for_jars/*
    docker build --build-arg ORIGIN_JAR=./tmp_for_jars/$ARTIFACT.jar --build-arg DESTINATION_JAR=$ARTIFACT.jar --build-arg BUILD_ID_INFO=$DOCKER_STACK_IMAGE_VERSION --tag $2:$DOCKER_STACK_IMAGE_VERSION --tag $2:$STACK_VERSION  --tag $2:latest  .

    rc=$?

    popd

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar

    if [[ $rc -ne 0 ]] ; then
      echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi

    echo "Hemos creado imagen para $1, $ARTIFACT --> $2 ($DOCKER_STACK_IMAGE_VERSION)"

}

function build_image_for_tomcat
{
    ## Esperamos como argumentos el directorio del artefacto (proyecto) y el nombre de la imagen
    pushd ../$1

    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')

    popd

    BASEDOCKERDIR=./docker_images_definitions/tomcat

    rm $BASEDOCKERDIR/tmp_for_jars/*.war

    echo "Copiamos ../$1/target/$ARTIFACT.war"

    ls ../$1/target/

    echo "--------------------------"

    cp ../$1/target/$ARTIFACT.war $BASEDOCKERDIR/tmp_for_jars/ROOT.war
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Bulild IMAGE ERROR error (copia binario) : '; exit $rc
    fi

    pushd $BASEDOCKERDIR

    pwd
    ls ./tmp_for_jars/*
    docker build --tag $2:$DOCKER_STACK_IMAGE_VERSION --tag $2:$STACK_VERSION --tag $2:latest  .

    rc=$?

    popd

    rm $BASEDOCKERDIR/tmp_for_jars/*.war

    if [[ $rc -ne 0 ]] ; then
      echo "Bulild IMAGE ERROR error (build): $rc [docker build --tag $2:$DOCKER_STACK_IMAGE_VERSION  --tag $2:latest  .]"; exit $rc
    fi

}

echo $(date +%s) > ./stack_definitions/last_build_version.txt
export DOCKER_STACK_IMAGE_VERSION=$STACK_VERSION\.$(cat ./stack_definitions/last_build_version.txt)

echo "Building restapi image?"
# Construimos los javas
if [ -d "../mephmicro-restapiApp" ]; then
    build_image_for_java mephmicro-restapiApp $DOCKER_RESTAPI_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi;


echo "Building engine image?"
if [ -d "../mephmicro-engineApp" ]; then
    build_image_for_java mephmicro-engineApp $DOCKER_ENGINE_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi

echo "Building singleapp image?"
if [ -d "../mephmicro-singleApp" ]; then
    build_image_for_tomcat mephmicro-singleApp $DOCKER_SINGLEAPP_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi
