#!/usr/bin/env bash

./04_01_publish_images.sh $@

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo 'Deploy - Error publishing images'; exit $rc
fi

./04_02_deploy_stack.sh $@

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo 'Deploy - Error deploying stack'; exit $rc
fi

echo "Deploy complete!!!"