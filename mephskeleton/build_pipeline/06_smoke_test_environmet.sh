#!/bin/bash

. ./00_env_pipeline.sh

aplicaEntorno $PIPELINE_ENVIRONMENT

check_result=0

function testHealth
{
    status=$(curl $1 | jq -r .status);

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echoerr "Error in healthcheck  $1"; exit $rc
    fi

    echo "Ckecking [$status]"

    if [[ "$status" == "UP" ]] ; then
       echo "health ok"
    else
       exit 1;
    fi;
}

function testVersion
{
    version=$(curl $1 | jq -r .app.version);

    rc=$?
    if [ $rc -ne 0 ] ; then
      echoerr "Error in version check $1"; exit $rc
    fi

    echo "Checking version [$2] vs [$version]"
    if [ "$version" == "$2" ]; then
        echo "Version ok"
    else
        echoerr "Error validating version."
        exit 1;
    fi;
}

function checkHealthAndVersion
{
    echo "CheckHealth - Launching smoke test to validate version."
    cat tmp/urls_health.txt | while read urlhealth;
    do
        echo "Validando $urlhealth"

        testHealth $urlhealth;

        rc=$?
        if [[ $rc -ne 0 ]] ; then
          echoerr "CheckHealth - healthcheck error"; return $rc
        fi
        echo "CheckHealth - health ok for $urlhealth"
    done;

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "CheckHealth - Error checking healthcheck";
      return $rc;
    else
        echo "CheckHealth - check version for $URLS_VERSION_CHECK"


        cat tmp/urls_version.txt  | tr ',' '\n' | while read urlVersion;
        do
            echo "CheckHealth - checking $urlVersion $STACK_VERSION"
            testVersion $urlVersion $STACK_VERSION;
            rc=$?
            if [[ $rc -ne 0 ]] ; then
              echoerr 'CheckHealth - Error in version checj $urlVersion $STACK_VERSION'; return $rc
            fi

            echo 'CheckHealth - Version ok for $STACK_VERSION $urlVersion'
        done;

    fi
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echoerr 'CheckHealth - Error checking and version.'; return $rc
    fi
    return 0
}

domain=$RESTAPI_K8S_DOMAIN_NAME_PREFIX$RESTAPI_K8S_DOMAIN_NAME$RESTAPI_K8S_DOMAIN_NAME_POSTFIX
echo "$domain/health" > tmp/urls_health.txt 
echo "$domain/info" > tmp/urls_version.txt 


COUNTER=0
rc=0
while [  $COUNTER -lt 40 ]; do

    echo "CheckHealth - launching check, try attempt $COUNTER"

    checkHealthAndVersion;

    rc=$?
    echo "CheckHealth - test result : $rc"

    if [[ $rc -ne 0 ]] ; then
        let COUNTER=$COUNTER+1;
        echoerr "CheckHealth - trying for $COUNTER time";
        sleep 3
    else
        let COUNTER=100;
    fi
done;

if [[ $rc -ne 0 ]] ; then
  echoerr 'CheckHealth - Error en check health / version'; exit -1
fi

echo 'CheckHealth - check ok'

