#!/usr/bin/env bash
./01_01_build_software.sh $@

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error building software'; exit $rc
fi

./01_02_build_unit_tests.sh $@

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error building unit tests'; exit $rc
fi

if [[ ! $SONAR_GOAL ]]; then
    ./01_03_build_sonar.sh $@

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error sonar'; exit $rc
    fi
fi

echo "Build complete!!!"

