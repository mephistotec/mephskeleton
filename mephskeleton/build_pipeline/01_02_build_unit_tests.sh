#!/usr/bin/env bash
. ./00_env_pipeline.sh

RESCODE=0

pushd ..

mvn $MAVEN_SETTINGS -e test

rc=$?
if [[ $rc -ne 0 ]] ; then
  RESCODE=$rc
fi

popd

if [[ $RESCODE -ne 0 ]] ; then
  echoerr 'Build error : $RESCODE'
  exit $RESCODE
else
  echoerr "Build OK"
fi

