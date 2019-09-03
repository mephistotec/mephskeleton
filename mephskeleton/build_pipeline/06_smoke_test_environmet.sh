#!/usr/bin/env bash
#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# es necesario que especifiquemos el entorno a verificar -e <entorno> asi
# como la version que deberiamos tener en ese entorno -v
#--------------------------------------------------------------------------

. ./00_env_pipeline.sh

aplicaEntorno $ENTORNO_PIPELINE

resultado_check=0

function testHealth
{
    estado=$(curl $1 | jq -r .status);

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo "--- Error en script healthcheck  $1"; exit $rc
    fi

    echo "Validando [$estado]"

    if [[ "$estado" == "UP" ]] ; then
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
      echo "--- Error en script version $1"; exit $rc
    fi

    echo "Comparando version [$2] vs [$version]"
    if [ "$version" == "$2" ]; then
        echo "version ok"
    else
        echo "Error validando version"
        exit 1;
    fi;
}

function checkHealthAndVersion
{
    #echo "Validando health para $URLS_HEALTH_CHECK"

    cat tmp/urls_health.txt | while read urlhealth;
    do
        echo "Validando $urlhealth"

        testHealth $urlhealth;

        rc=$?
        if [[ $rc -ne 0 ]] ; then
          echo '--- Error en healthcheck'; return $rc
        fi
        echo "Health OK para $urlhealth"
    done;

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error en healthcheck, no miramos versiones';
      return $rc;
    else
        echo "Validando VERSION para $URLS_VERSION_CHECK"


        cat tmp/urls_version.txt  | tr ',' '\n' | while read urlVersion;
        do
            echo "Validando $urlVersion $DOCKER_STACK_VERSION"
            testVersion $urlVersion $DOCKER_STACK_VERSION;
            rc=$?
            if [[ $rc -ne 0 ]] ; then
              echo '--- Error en check version $urlVersion $DOCKER_STACK_VERSION'; return $rc
            fi

            echo "Version OK para $DOCKER_STACK_VERSION $urlVersion"
        done;

    fi
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Error en check health / version'; return $rc
    fi
    echo "Test Completo"
    return 0
}


COUNTER=0
rc=0
while [  $COUNTER -lt 40 ]; do

    echo "Lanzamos test , iteracion $COUNTER"

    checkHealthAndVersion;

    rc=$?
    echo "resultado test : $rc"

    if [[ $rc -ne 0 ]] ; then
        let COUNTER=$COUNTER+1;
        echo "Intento de validacion $COUNTER. Nos dormimos 30s esperando";
        sleep 3
    else
        let COUNTER=100;
    fi
done;

if [[ $rc -ne 0 ]] ; then
  echo '--- Error en check health / version'; exit -1
fi

echo "Test de healt y version correcto"

