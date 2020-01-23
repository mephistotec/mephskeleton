#!/usr/bin/env bash
. ./00_env_pipeline.sh

basePath=$(pwd)

function splitJarIntoFrameworkAndCode
{
    ARTIFACT=$1
    WRKDIR=$2
    ORIGIN=$3

    echo "Building image, decompressing $ARTIFACT.jar with $WRKDIR and $ORIGIN"
    mkdir -p $WRKDIR/decomp
    rm -R $WRKDIR/decomp/*
    
    echo "Building image, looking for ../$1/target/$ARTIFACT.jar"
    cp $ORIGIN/$ARTIFACT.jar $WRKDIR/decomp
    echo "Building image, decompressing $ARTIFACT.jar"

    pushd $BASEDOCKERDIR/tmp_for_jars/decomp
      unzip ./$ARTIFACT.jar;
      rm  ./$ARTIFACT.jar;
      echo "Building image, splitting content of docker image: framework and code for $ARTIFCAT"
      rm ../micro_content.txt
      rm ../framework_content.txt
      find . -type f | grep -v lib | grep -v "org/springframework/boot/loader" > ../micro_content.txt;find . -type f | grep lib | grep mephmicro >> ../micro_content.txt
      find . -type f | grep "org/springframework/boot/loader" > ../framework_content.txt; find . -type f | grep lib | grep -v mephmicro >> ../framework_content.txt
      echo "Building image, zipping service code into $(pwd)/../$ARTIFACT_JAR.jar"
      zip ../$ARTIFACT_JAR.jar -m -n .jar -@ < ../micro_content.txt
      echo "Building image, zipping service code into $(pwd)/$FRAMEWORK_JAR_NAME.jar"
      zip ../$FRAMEWORK_JAR_NAME.jar -m -n .jar -@ < ../framework_content.txt
    popd
    rm -R $WRKDIR/decomp/*
    rm $WRKDIR/*.txt
}

function build_image_for_java
{
    echo "   building image for $1"
    pushd ../$1
    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')
    popd

    FRAMEWORK_JAR_NAME=$ARTIFACT"_framework"
    ARTIFACT_JAR=$ARTIFACT"_code"

    BASEDOCKERDIR=./docker_images_definitions/java

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar
    mkdir -p $BASEDOCKERDIR/tmp_for_jars/decomp
    rm -R $BASEDOCKERDIR/tmp_for_jars/decomp/*

    echo "   build images, splittinh jars into framework and service"    
    splitJarIntoFrameworkAndCode $ARTIFACT $BASEDOCKERDIR/tmp_for_jars ../$1/target
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Bulild IMAGE ERROR error : '; exit $rc
    fi
    echo "-------------------- ANTES DE IMAGES ---------------------"
    ls -la $BASEDOCKERDIR/tmp_for_jars
    echo "----------------------------------------------------"
    pushd $BASEDOCKERDIR
    echo "Building image, binaries ready for framework"
      #docker build  -f Dockerfile_framework --build-arg ORIGIN_JAR=./tmp_for_jars/$FRAMEWORK_JAR_NAME.jar --build-arg DESTINATION_JAR=$FRAMEWORK_JAR_NAME.jar --tag $3:latest .
      echo "Building image, binaries ready for $1, $ARTIFACT --> $2:($DOCKER_STACK_IMAGE_VERSION)     (./tmp_for_jars/$ARTIFACT_JAR.jar , $ARTIFACT_JAR.jar) "      
      docker build  --build-arg FINAL_JAR=$ARTIFACT.jar --build-arg ORIGIN_JAR=./tmp_for_jars/$ARTIFACT_JAR.jar --build-arg DESTINATION_JAR=$ARTIFACT_JAR.jar --build-arg BUILD_ID_INFO=$DOCKER_STACK_IMAGE_VERSION  --build-arg BASE_IMAGE=$3  --tag $2:$DOCKER_STACK_IMAGE_VERSION --tag $2:$STACK_VERSION  --tag $2:latest .
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
    build_image_for_java mephmicro-restapiApp $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_RESTAPI_FWK_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi;

echo "Building engine image?"
if [ -d "../mephmicro-engineApp" ]; then
    echo "Building image, building image for engine, $DOCKER_RESTAPI_IMAGE_NAME"
    build_image_for_java mephmicro-engineApp $DOCKER_ENGINE_IMAGE_NAME $DOCKER_ENGINE_FWK_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi