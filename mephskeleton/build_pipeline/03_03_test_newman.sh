#!/usr/bin/env bash

. ./00_env_pipeline.sh

aplicaEntorno mockservers

echoerr "--- Preparamos el entorno de aceptacion"
errorEjecucion=0

function lanzaNewman
{
    stopNewman

    echo "Lanzando newman ..."

    netname=$( docker network ls | grep test_integ_network | sed -E 's/[ ]+/ /g' | cut -d" " -f2);
    for fichero in mockservers_images/docker_newman_image/test_integracion_scripts/POSTMAN*; do
        fichero=$(echo $fichero | cut -d"/" -f4)
        echo "Estamos en $(pwd)"
        echo "Ejecutando docker run -v $(pwd)/mockservers_images/docker_newman_image/test_integracion_scripts:/scripts --rm -t --network=$netname newman_mng newman run  /scripts/$fichero -e /scripts/env_postman-local.json;"
        docker run  --rm -t --network=$netname newman_mng newman run  /scripts/$fichero -e /scripts/env_postman-local.json;
        rc=$?
        if [[ $rc -ne 0 ]] ; then
            echoerr="NEWMAN HA DETECTADO UN ERROR $rc $fichero"
            errorEjecucion=$rc
        fi
    done
}

function stopNewman
{
    docker ps | grep newman_mng |cut -d" " -f1 | while read contenedor; do echo "parando newman $contenedor";docker stop $contenedor;done
}

lanzaNewman

rc=errorEjecucion
if [[ $rc -ne 0 ]] ; then
    echo FAIL en la ejecucion de los tests de aceptación
    exit $rc
else
    echo OK test aceptación
fi
