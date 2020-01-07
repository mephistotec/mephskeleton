#!/usr/bin/env bash

./01_01_build_software.sh -f devcasa

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error building software'; exit $rc
fi

02_docker_build_images.sh -f devcasa

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error building images'; exit $rc
fi

./03_test_integracion.sh -f devcasa

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error testing soft '; exit $rc
fi


#4_deploy.sh -f devcasa -f registrymng_pre -e pre
#
#rc=$?
#if [[ $rc -ne 0 ]] ; then
#  echo '--- Error testing soft '; exit $rc
#fi
