#!/usr/bin/env bash

#Inicializamos el entorno sin necesitar parametros adicionales pues los jar estan generados
. ./00_env_pipeline.sh

pintaQueScriptSoy

aplicaEntorno $ENTORNO_PIPELINE

echo "entorno $ENTORNO_PIPELINE para subir a S3"
if [ "$ENTORNO_PIPELINE" == "" ];
then
    echo "ERROR falta entorno, se ha de especificar un entorno y se pueden especificar flags para inicializar registro a usar"
    echo "Uos 04_deploy_stack.sh <entorno> <flag de registry>"
    exit -1
fi

BASEZIPDIR=./tmp/zip_s3_files/
rm $BASEZIPDIR/*.txt

NAME_ZIP=test-batch-$ARTIFACT_VERSION-zip.zip
FILE_ZIP=$BASEZIPDIR/$NAME_ZIP

export AWS_ACCESS_KEY_ID=$CICD_S3_USER
export AWS_SECRET_ACCESS_KEY=$CICD_S3_PASS

echo "Copiamos $BASEZIPDIR/test-$ARTIFACT_VERSION.zip a S3 ($S3_LSDOMAINS_PATH) con $AWS_ACCESS_KEY_ID"
echo "--------------------------"

# volcamos los parametros para que los recoja el jeninsfile
# volcamos los parametros para que los recoja el jeninsfile
echo "softbase" > ./tmp/zip_s3_files/LAST_GROUPNAME_WDPRE.txt
echo "test" > ./tmp/zip_s3_files/LAST_ARTIFACT_WDPRE.txt
echo "$ARTIFACT_VERSION" > ./tmp/zip_s3_files/LAST_VERSION_WDPRE.txt

aws s3 cp $FILE_ZIP  s3://$S3_LSDOMAINS_PATH/test-batch-$ARTIFACT_VERSION.zip


rc=$?
if [[ $rc -ne 0 ]] ; then
   echo "Error upload S3 () : $rc"; exit $rc
fi
