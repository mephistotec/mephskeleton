#!/usr/bin/env bash

. ./00_env_pipeline.sh

echo "Promoting - Prepating deploying stack ...."

./04_02_deploy_stack.sh -e pro

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error Desplegando stack'; exit $rc
fi

echo "Deploy complete!!!"