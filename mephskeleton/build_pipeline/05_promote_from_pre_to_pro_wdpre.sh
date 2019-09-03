#!/usr/bin/env bash
#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# DOCKER_STACK_VERSION - Version a desplegar
# DOCKER_REGISTRY_MNG_BASE_URL - URL de registry de PRE (base)
# DOCKER_REGISTRY_MNG_BASE_URL - URL de registry de PRO (base)
# DOCKER_REGISTRY_MNG_USER - Usuario de acceso al registry
# DOCKER_REGISTRY_MNG_PASSWORD - password de acceso al registry
#
#--------------------------------------------------------------------------

. ./00_env_pipeline.sh

version_to_promote=$DOCKER_STACK_VERSION

if [ "version_to_promote" == "" ];
then
    echo "ERROR Especifica la versión a promover"
    echo "Uos 05_promote_to_pro.sh -v <version a promover a PRO>"
    exit -1
fi


function pullPushZip
{
   pi_S3_ORIGEN_URL="s3://$S3_MNG_PRE_BASE_URL"
   pi_S3_DESTINO_URL="s3://$S3_MNG_PRO_BASE_URL"
   pi_VERSION=$1
   artifactName="mephskeleton-batch"

   BASEZIPDIR=./tmp/zip_s3_files/
   FILE_ZIP=$BASEZIPDIR/mephskeleton-$pi_VERSION.zip

    rm $BASEZIPDIR/*.zip

    export AWS_ACCESS_KEY_ID=$CICD_S3_USER
    export AWS_SECRET_ACCESS_KEY=$CICD_S3_PASS

    echo "Copiamos $BASEZIPDIR/$artifactName-$pi_VERSION.zip de  S3 ($pi_S3_ORIGEN_URL) a ($pi_S3_DESTINO_URL) con $AWS_ACCESS_KEY_ID"

    aws s3 cp $pi_S3_ORIGEN_URL/$artifactName-$pi_VERSION.zip ./tmp/zip_s3_files/
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "--- Error Recuperando version origen $BASEZIPDIR/$artifactName-$pi_VERSION.zip de  S3 ($pi_S3_ORIGEN_URL) !!!"; exit $rc
    fi

    echo "Subimos a PRO $BASEZIPDIR/$artifactName-$pi_VERSION.zip de  S3 ($pi_S3_ORIGEN_URL) a ($pi_S3_DESTINO_URL) con $AWS_ACCESS_KEY_ID"
    aws s3 cp ./tmp/zip_s3_files/$artifactName-$pi_VERSION.zip $pi_S3_DESTINO_URL/$artifactName-$pi_VERSION.zip
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "--- Error Almacenando version destino $BASEZIPDIR/mephskeleton-$pi_VERSION.zip de  S3 ($pi_S3_DESTINO_URL) !!!"; exit $rc
    fi
}


#Publicamos las imagenes de los dos artefactos
if [ -d "../mephskeleton-batch" ]; then
    pullPushZip $ARTIFACT_VERSION
fi

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error Promote ZIP'; exit $rc
fi

echo "Deploy complete!!!"