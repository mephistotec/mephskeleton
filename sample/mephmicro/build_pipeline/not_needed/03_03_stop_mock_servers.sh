#!/usr/bin/env bash

#
# En el script de entonro 00_env_pipeline se definen las variables
#
# STACK_VERSION  -- Se actualiza con la version del POM a no ser que se defina flag -v
# ADDITIONAL_COMPOSES  -- Composes a usar para la generacion del STACK, varia en funcion del entorno mock, pre, pro
# compose_salida_integracion -- Determina el compose a usar para parar el stak. Se define al aplicar el entorno


. ./00_env_pipeline.sh

aplicaEntorno mockservers

pushd ./stack_definitions/
    docker-compose -f ./config_generada/$compose_salida_integracion down
    rc=$?
    if [[ $rc -ne 0 ]] ; then
        echo FAIL parando mock servers
    else
        echo Parado entorno mock
    fi
popd

exit $rc