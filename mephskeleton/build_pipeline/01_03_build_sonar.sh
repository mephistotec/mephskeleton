#!/bin/bash
. ./00_env_pipeline.sh

RESCODE=0

pushd ..

echo "$SONAR_PARAMS"

#Para evitar problemas de depedencias entre modulos
mvn $MAVEN_SETTINGS $SONAR_PARAMS  sonar:sonar

rc=$?
if [[ $rc -ne 0 ]] ; then
  RESCODE=$rc
fi

popd

if [[ $RESCODE -ne 0 ]] ; then
  echo 'Build sonar error'
  exit $RESCODE
else
  echo "Build OK"
fi
