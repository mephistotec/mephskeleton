#!/usr/bin/env bash

echo "------------------------------------------------------"
echo "------------------------------------------------------"
echo "---------- VALIDANDO ENTORNO MOCK $(pwd) -------------"
echo "------------------------------------------------------"
echo "------------------------------------------------------"

COUNTER=0

while [  $COUNTER -lt 50 ]; do
    # Nos quedamos hasta que el entorno esta ok
    netname=$( docker network ls | grep test_integ_network | sed -E 's/[ ]+/ /g' | cut -d" " -f2);
    STATUS_RESTAPI="UP"
    STATUS_ENGINE="UP"
    STATUS_TOMCAT="UP"
     #Cogemos los composes relevantes
    if [ -d "../test-restapiApp" ]; then
        STATUS_RESTAPI=$(docker run --network=$netname --rm appropriate/curl -fsSL http://test_restapi_external:8080/health | jq  -r ".status");
        echo "------- VALIDAMOS RESTAPI $STATUS_RESTAPI -------"
    fi;
    if [ -d "../test-engineApp" ]; then
        STATUS_ENGINE=$(docker run --network=$netname --rm appropriate/curl -fsSL http://test_engine_external:8080/health | jq -r ".status");
        echo "------- VALIDAMOS ENGINE $STATUS_ENGINE -------"
    fi;
    if [ -d "../test-singleApp" ]; then
        STATUS_TOMCAT=$(docker run --network=$netname --rm appropriate/curl -fsSL http://test_singleapp_external:8080/health | jq -r ".status");
        echo "------- VALIDAMOS WEBAPP $STATUS_TOMCAT -------"
    fi;
    echo "-------- ESTADOS [$STATUS_RESTAPI][$STATUS_ENGINE][$STATUS_TOMCAT]"

    if [[ "$STATUS_RESTAPI" == "UP" && "$STATUS_ENGINE" == "UP" && "$STATUS_TOMCAT" == "UP"  ]] ; then
        let COUNTER=100;
    else
        let COUNTER=$COUNTER+1;
        echo "Nos dormimos 5s esperando";
        sleep 5
    fi
done;

if [[ "$STATUS_RESTAPI" == "UP" && "$STATUS_RESTAPI" == "UP"  && "$STATUS_TOMCAT" == "UP" ]] ; then
    echo "OK,preparado el entorno mock"
else
    echo "-------------------------------------------------"
    echo "-------------------------------------------------"
    echo "-------------------------------------------------"
    echo "FAIL inicializando contexto de mock servers"
    echo "-------------------------------------------------"
    echo "-------------------------------------------------"
    echo "-------------------------------------------------"
    exit -1;
fi
