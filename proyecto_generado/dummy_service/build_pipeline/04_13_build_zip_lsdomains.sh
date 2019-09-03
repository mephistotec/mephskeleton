#!/usr/bin/env bash

#Inicializamos el entorno sin necesitar parametros adicionales pues los jar estan generados
. ./00_env_pipeline.sh


function build_zip
{
    ## Esperamos como argumentos el directorio del artefacto (proyecto) y el nombre de la imagen
    pushd ../$1

    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')
    echo "Hemos copiado binarios para $1, $ARTIFACT --> $2:($ARTIFACT_VERSION)"

    popd

    BASEZIPDIR=./tmp/zip_s3_files/

    rm $BASEZIPDIR/*.zip
    rm $BASEZIPDIR/*.txt

    echo "Copiamos ../$1/target/$ARTIFACT.war"
    echo "--------------------------"
    cp ../$1/target/$ARTIFACT.war $BASEZIPDIR/dummy_service-$ARTIFACT_VERSION.war
    zip -j $BASEZIPDIR/dummy_service-$ARTIFACT_VERSION.zip $BASEZIPDIR/dummy_service-$ARTIFACT_VERSION.war

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Bulild ZIP ERROR error (copia binario) : '; exit $rc
    fi
}


# Construimos los javas
if [ -d "../dummy_service-restapiApp" ]; then
    echo "VERSION JAR NOT IMPLEMENTED FOR LSDOMAINS2";
    exit -1;
fi;


if [ -d "../dummy_service-engineApp" ]; then
    echo "VERSION JAR NOT IMPLEMENTED FOR LSDOMAINS2";
    exit -1;
fi

if [ -d "../dummy_service-singleApp" ]; then
    build_zip dummy_service-singleApp
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild ZIP ERROR error : $rc"; exit $rc
    fi
fi

