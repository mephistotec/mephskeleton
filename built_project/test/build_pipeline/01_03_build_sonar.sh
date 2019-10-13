#!/usr/bin/env bash
. ./00_env_pipeline.sh

RESCODE=0

pushd ..

mvn   $MAVEN_SETTINGS $SONAR_PARAMS  sonar:sonar

rc=$?
if [[ $rc -ne 0 ]] ; then
  RESCODE=$rc
fi

popd

if [[ $RESCODE -ne 0 ]] ; then
  echo '---- SONAR error'
  exit $RESCODE
else
  echo "Build OK"
fi
