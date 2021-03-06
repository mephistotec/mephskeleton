#!/bin/bash
. ./00_env_pipeline.sh

basePath=$(pwd)

FRAMEWORK_VERSION=0

function calculate_framework_version
{
  FRAMEWORK_VERSION=$(mvn dependency:tree | grep ":" | grep -v mephskeleton  | grep -v Total | grep -v Finish | md5)
  if [[ "$FRAMEWORK_VERSION" == "" ]] ; then
    echo "Building image - cannot use hash, looking for simulation of hash ..."
    NUM_DEPENDENCIES=$(mvn dependency:tree | grep ":" | grep -v mephskeleton  | grep -v Total | grep -v Finish | wc -l)
    DEP_SIZE=$(mvn dependency:tree | grep ":" | grep -v mephskeleton  | grep -v Total | grep -v Finish | wc -c)
    FRAMEWORK_VERSION=$(echo "$NUM_DEPENDENCIES$DEP_SIZE" | xargs | sed 's/ //g')
  fi
  echo "Building image - calculated framework version as $FRAMEWORK_VERSION"
}

function splitJarIntoFrameworkAndCode
{
    ARTIFACT=$1
    WRKDIR=$2
    ORIGIN=$3
    FRAMEWORK_EXISTS=$4

    echo "Building image - decompressing $ARTIFACT.jar with $WRKDIR and $ORIGIN"
    mkdir -p $WRKDIR/decomp
    rm -R $WRKDIR/decomp/*
    
    echo "Building image - looking for ../$1/target/$ARTIFACT.jar"
    cp $ORIGIN/$ARTIFACT.jar $WRKDIR/decomp
    echo "Building image - decompressing $ARTIFACT.jar"

    pushd $BASEDOCKERDIR/tmp_for_jars/decomp
      unzip -q ./$ARTIFACT.jar;
      rm  ./$ARTIFACT.jar;
      echo "Building image - splitting content of docker image: framework and code for $ARTIFCAT"
      rm ../micro_content.txt
      rm ../framework_content.txt
      find . -type f | grep -v lib | grep -v "org/springframework/boot/loader" > ../micro_content.txt;find . -type f | grep lib | grep mephskeleton >> ../micro_content.txt
      find . -type f | grep "org/springframework/boot/loader" > ../framework_content.txt; find . -type f | grep lib | grep -v mephskeleton >> ../framework_content.txt
      echo "Building image - zipping service code into $(pwd)/../$ARTIFACT_JAR.jar"
      zip ../$ARTIFACT_JAR.jar -q -m -n .jar -@ < ../micro_content.txt
      if [[ $FRAMEWORK_EXISTS -ne 1 ]]; then
        echo "Building image - zipping service code into $(pwd)/$FRAMEWORK_JAR_NAME.jar"
        zip ../$FRAMEWORK_JAR_NAME.jar -q -m -n .jar -@ < ../framework_content.txt
      else
        echo "Building image - framework jar not needed";
      fi
    popd
    rm -R $WRKDIR/decomp/*
    rm $WRKDIR/*.txt
}

function build_image_for_java
{
    echo "Building image - building image for $1"
    pushd ../$1
      ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')
      calculate_framework_version      
      FRAMEWORK_EXISTS=$(docker images | grep "$3" | grep "$FRAMEWORK_VERSION" | wc -l )
      echo "Building image - Does framework exist ($3:$FRAMEWORK_VERSION)? $FRAMEWORK_EXISTS"
    popd

    FRAMEWORK_JAR_NAME=$ARTIFACT"_framework"
    ARTIFACT_JAR=$ARTIFACT"_code"

    FRAMEWORK_LABEL=$ARTIFACT"_framework:"$STACK_VERSION
    ARTIFACT_LABEL=$ARTIFACT":"$STACK_VERSION

    BASEDOCKERDIR=./docker_images_definitions/java

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar
    mkdir -p $BASEDOCKERDIR/tmp_for_jars/decomp
    rm -R $BASEDOCKERDIR/tmp_for_jars/decomp/*

    echo "Building image - build images, splittinh jars into framework and service"    
    splitJarIntoFrameworkAndCode $ARTIFACT $BASEDOCKERDIR/tmp_for_jars ../$1/target $FRAMEWORK_EXISTS
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Building image - Bulild IMAGE ERROR error : '; exit $rc
    fi

    pushd $BASEDOCKERDIR
      if [[ $FRAMEWORK_EXISTS -ne 1 ]]; then
        echo "Building image - binaries ready for framework $3:$FRAMEWORK_VERSION"
        docker build  -f Dockerfile_framework --build-arg LABELFWK="$FRAMEWORK_LABEL" --build-arg ORIGIN_JAR=./tmp_for_jars/$FRAMEWORK_JAR_NAME.jar --build-arg DESTINATION_JAR=$FRAMEWORK_JAR_NAME.jar --tag $3:$FRAMEWORK_VERSION .
      else
        echo "Building image - Existing version of framework is the latest, don't need to create";
      fi
      echo "Building image - binaries ready for $1, $ARTIFACT (./tmp_for_jars/$ARTIFACT_JAR.jar , $ARTIFACT_JAR.jar) "
      docker build  --build-arg FINAL_JAR=$ARTIFACT.jar --build-arg LABEL="$ARTIFACT_LABEL" --build-arg ORIGIN_JAR=./tmp_for_jars/$ARTIFACT_JAR.jar --build-arg DESTINATION_JAR=$ARTIFACT_JAR.jar --build-arg BASE_IMAGE=$3:$FRAMEWORK_VERSION --tag $2:$STACK_VERSION .
      rc=$?
    popd

    rm $BASEDOCKERDIR/tmp_for_jars/*.jar

    if [[ $rc -ne 0 ]] ; then
      echo "Building image - Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
    echo "Building image - we've built image for $1, $ARTIFACT --> $2"
}

# Build java artifacts
if [ -d "../mephskeleton-restapiApp" ]; then
    echo "Building image - building image for restApi  ($DOCKER_RESTAPI_IMAGE_NAME)"
    build_image_for_java mephskeleton-restapiApp $DOCKER_RESTAPI_IMAGE_NAME $DOCKER_RESTAPI_FWK_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi;

if [ -d "../mephskeleton-engineApp" ]; then
    echo "Building image - building image for engine, $DOCKER_RESTAPI_IMAGE_NAME"
    build_image_for_java mephskeleton-engineApp $DOCKER_ENGINE_IMAGE_NAME $DOCKER_ENGINE_FWK_IMAGE_NAME
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Building image - Bulild IMAGE ERROR error : $rc"; exit $rc
    fi
fi
