#!/bin/bash
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

