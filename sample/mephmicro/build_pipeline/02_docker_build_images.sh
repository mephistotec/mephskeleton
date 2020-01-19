#!/usr/bin/env bash
. ./00_env_pipeline.sh

basePath=$(pwd)


function splitJarIntoFrameworkAndCode
{
    ARTIFACT=$1
    WRKDIR=$2
    ORIGIN=$3
    FRAMEWORK_JAR_NAME=$ARTIFACT"_framework"
    ARTIFACT_JAR=$ARTIFACT"_code"

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
      #cat ../micro_content.txt | while read fichero; do echo $fichero;zip -m ../$ARTIFACT_JAR.jar $fichero;done;
      echo "Building image, zipping service code into $(pwd)/$FRAMEWORK_JAR_NAME.jar"
      zip ../$FRAMEWORK_JAR_NAME.jar -m -n .jar -@ < ../framework_content.txt
      #cat ../framework_content.txt | while read fichero; do echo $fichero; zip -m ../$FRAMEWORK_JAR_NAME.jar $fichero;done;
    popd
    rm -R $WRKDIR/decomp/*
}

function joinJars 
{
    SERVICE_JAR=$1
    FRAMEWORK_JAR=$2
    RESULT_JAR=$3
    WRKDIR=$4

    echo "Building fina imaje: joining jars $SERVICE_JAR $FRAMEWORK_JAR into $RESULT_JAR in $WRKDIR"
    mkdir -p $WRKDIR/decomp
    rm -R $WRKDIR/decomp/*
    cp $1 $WRKDIR/decomp
    cp $2 $WRKDIR/decomp
  
    pushd $WRKDIR/decomp
      echo "------- Files to process ------"
      ls
      echo "------- decompressiong ------"
      ls | while read fichero; do unzip $fichero; done;
      unzip *.jar
      rm *.jar
      zip  $RESULT_JAR -m -n .jar -r *
    popd
}

function build_image_for_java
{
    echo "building image for $1"
    pushd ../$1
    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')
    popd

    BASEDOCKERDIR=./docker_images_definitions/java

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar
    mkdir -p $BASEDOCKERDIR/tmp_for_jars/decomp
    rm -R $BASEDOCKERDIR/tmp_for_jars/decomp/*
    
    splitJarIntoFrameworkAndCode $ARTIFACT $BASEDOCKERDIR/tmp_for_jars ../$1/target


    FRAMEWORK_JAR_NAME=$ARTIFACT"_framework"
    ARTIFACT_JAR=$ARTIFACT"_code"

    joinJars $BASEDOCKERDIR/tmp_for_jars/$FRAMEWORK_JAR_NAME".jar" $BASEDOCKERDIR/tmp_for_jars/$ARTIFACT_JAR".jar" $ARTIFACT"_join".jar $BASEDOCKERDIR/tmp_for_jars

    # rm -R $BASEDOCKERDIR/tmp_for_jars/decomp/*

    # rc=$?
    # if [[ $rc -ne 0 ]] ; then
    #   echo 'Bulild IMAGE ERROR error : '; exit $rc
    # fi

    # echo "Building image, binaries ready for $1, $ARTIFACT --> $2:($DOCKER_STACK_IMAGE_VERSION)"

    # pushd $BASEDOCKERDIR

    # pwd
    # ls ./tmp_for_jars/*
    # docker build --build-arg ORIGIN_JAR=./tmp_for_jars/$ARTIFACT.jar --build-arg DESTINATION_JAR=$ARTIFACT.jar --build-arg BUILD_ID_INFO=$DOCKER_STACK_IMAGE_VERSION --tag $2:$DOCKER_STACK_IMAGE_VERSION --tag $2:$STACK_VERSION  --tag $2:latest  .

    # echo "Building image, Image has been built for $ARTIFACT"

    # rc=$?

    # popd

    # rm $BASEDOCKERDIR/tmp_for_jars/*.jar

    # if [[ $rc -ne 0 ]] ; then
    #   echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    # fi

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