#!/usr/bin/env bash
##
## Pueden venir predefinidas las siguientes variables:
## SONAR_GOAL    -- define el goal sonar:sonar
## SONAR_PARAMS  -- define los parametros de sonar
## STACK_VERSION -- Si queremos setear la version para el stack  incluimos un flag -v , sino usamos la del pom
## MAVEN_SETTINGS -- por si queremos usar un fichero de settings diferente al de defecto de maven, p.e. el de mango
##
. ./00_env_pipeline.sh

RESCODE=0

pushd ..

#Para evitar problemas de depedencias entre modulos
mvn $MAVEN_SETTINGS -Dmaven.test.skip=true clean install

rc=$?
if [[ $rc -ne 0 ]] ; then
  RESCODE=$rc
fi

popd


if [[ $RESCODE -ne 0 ]] ; then
  echo '---- Bulild error : $RESCODE'
  exit $RESCODE
else
  echo "Build OK"
fi

