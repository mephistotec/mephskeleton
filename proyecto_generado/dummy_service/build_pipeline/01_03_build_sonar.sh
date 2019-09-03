#!/usr/bin/env bash
##
## Pueden venir predefinidas las siguientes variables:
## SONAR_GOAL    -- define el goal sonar:sonar
## SONAR_PARAMS  -- define los parametros de sonar
## DOCKER_STACK_VERSION -- Si queremos setear la version para el stack  incluimos un flag -v , sino usamos la del pom
## MAVEN_SETTINGS -- por si queremos usar un fichero de settings diferente al de defecto de maven, p.e. el de mango
##
. ./00_env_pipeline.sh

CODIGO_SALIDA=0

pushd ..


#Para evitar problemas de depedencias entre modulos
mvn   $MAVEN_SETTINGS $SONAR_PARAMS  sonar:sonar

rc=$?
if [[ $rc -ne 0 ]] ; then
  CODIGO_SALIDA=$rc
fi

popd

if [[ $CODIGO_SALIDA -ne 0 ]] ; then
  echo '---- SONAR error'
  exit $CODIGO_SALIDA
else
  echo "Build OK"
fi
