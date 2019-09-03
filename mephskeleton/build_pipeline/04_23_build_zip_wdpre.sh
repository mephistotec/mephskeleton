#!/usr/bin/env bash

#Inicializamos el entorno sin necesitar parametros adicionales pues los jar estan generados
. ./00_env_pipeline.sh

function build_zip
{
    ## Esperamos como argumentos el directorio del artefacto (proyecto) y el nombre de la imagen
    pushd ../$1

    ARTIFACT=$(mvn help:evaluate -Dexpression=project.build.finalName | grep -e '^[^\[]')
    echo "Generamos zip para $1, $ARTIFACT --> $2:($ARTIFACT_VERSION)"

    mvn $MAVEN_SETTINGS package -PdeployZip

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      popd
      echo 'Bulild ZIP ERROR error (copia binario) : '; exit $rc
    fi

    popd

    BASEZIPDIR=./tmp/zip_s3_files/

    rm $BASEZIPDIR/*.zip

    echo "Copiamos ../$1/target/$ARTIFACT.zip"
    echo "--------------------------"
    cp ../$1/target/$ARTIFACT-zip.zip $BASEZIPDIR/$ARTIFACT-zip.zip

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo 'Bulild ZIP ERROR error (copia binario) : '; exit $rc
    fi
}


if [ -d "../mephskeleton-batch" ]; then
    build_zip mephskeleton-batch
    rc=$?
    if [[ $rc -ne 0 ]] ; then
       echo "Bulild ZIP ERROR error : $rc"; exit $rc
    fi
fi

