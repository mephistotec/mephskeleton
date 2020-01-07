#!/usr/bin/env bash
. ./00_env_pipeline.sh

basePath=$(pwd)

function build_image_for_java
{
    echo "building image for $1"
    pushd ../$1

    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')
    popd

    BASEDOCKERDIR=./docker_images_definitions/java

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar
    
    echo "Building image, looking for ../$1/target/$ARTIFACT.jar"
    
    cp ../$1/target/$ARTIFACT.jar $BASEDOCKERDIR/tmp_for_jars/

    

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Bulild IMAGE ERROR error : '; exit $rc
    fi

    echo "Building image, binaries ready for $1, $ARTIFACT --> $2:($DOCKER_STACK_IMAGE_VERSION)"

    pushd $BASEDOCKERDIR

    pwd
    ls ./tmp_for_jars/*
    docker build --build-arg ORIGIN_JAR=./tmp_for_jars/$ARTIFACT.jar --build-arg DESTINATION_JAR=$ARTIFACT.jar --build-arg BUILD_ID_INFO=$DOCKER_STACK_IMAGE_VERSION --tag $2:$DOCKER_STACK_IMAGE_VERSION --tag $2:$STACK_VERSION  --tag $2:latest  .

    echo "Building image, Image has been built for $ARTIFACT"

    rc=$?

    popd

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar

    if [[ $rc -ne 0 ]] ; then
      echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi

    echo "Building image, we've built image for $1, $ARTIFACT --> $2 ($DOCKER_STACK_IMAGE_VERSION)"
}

echo $(date +%s) > ./stack_definitions/last_build_version.txt
export DOCKER_STACK_IMAGE_VERSION=$STACK_VERSION\.$(cat ./stack_definitions/last_build_version.txt)

# Construimos los javas
if [ -d "../mephmicro-restapiApp" ]; then
    echo "Building image, building image for restApi  ($DOCKER_RESTAPI_IMAGE_NAME)"
    build_image_for_java mephmicro-restapiApp $DOCKER_RESTAPI_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi;

echo "Building engine image?"
if [ -d "../mephmicro-engineApp" ]; then
    echo "Building image, building image for engine, $DOCKER_RESTAPI_IMAGE_NAME"
    build_image_for_java mephmicro-engineApp $DOCKER_ENGINE_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi