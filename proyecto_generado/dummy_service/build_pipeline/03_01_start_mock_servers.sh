#!/usr/bin/env bash

#
# En el script de entonro 00_env_pipeline se definen las variables
#
# DOCKER_STACK_VERSION  -- Se actualiza con la version del POM a no ser que se defina flag -v
# ADDITIONAL_COMPOSES  -- Composes a usar para la generacion del STACK, varia en funcion del entorno mock, pre, pro
#

. ./00_env_pipeline.sh

aplicaEntorno mockservers

echo "--- Preparamos el entorno de aceptacion"
echo "-----------------------------------"
env | grep DOCKER
echo "-----------------------------------"

# Reemeplzamos los paths que nos genera el docker-compose config para que sean correctos en jenkins que corre como docker
function arraglaYMLDockerBesideDoccker
{
    echo " Miramos si hemos de modificar $1"

    #Si estamos en docker in docker
    soyDocker=$(docker ps | grep $(hostname) | wc -l);

    if [ "$soyDocker" == "1" ];
    then
        for mapping in $(docker inspect $(hostname) | jq -r '.[0].Mounts[] | .Destination + ":"  + .Source' | sed -e 's/\//\\\//g');
        do
            echo " ----- arreglamos yml, estamos en docker --------";
            echo $mapping;
            echo " ------------------------------------------------";
            src=$(echo $mapping | awk -F":" '{print $1}');
            dst=$(echo $mapping | awk -F":" '{print $2}');
            case "$(uname -s)" in
               Darwin)
                 sed -i '' "s/$src/$dst/g" $1
                 ;;
               *)
                 sed -i "s/$src/$dst/g"  $1
                 ;;
            esac
            echo " ------------    acabado  -----------------------";
         done;
    else
        echo " ----- No hacemos nada con el yml, no estamos en docker"
    fi
}

# Reemeplzamos los paths que nos genera el docker-compose config para que sean correctos en jenkins que corre como docker
function arreglaPathsWindowsLinux
{
    echo " Miramos si hemos de modificar (arreglaPathsWindowsLinux) ($1)"

    if [ "$LINUXWONWIN" == "true" ];
    then
        echo " ----- arreglamos yml (arreglaPathsWindowsLinux), estamos en docker --------";

        src="\/mnt\/c\/";
        dst="\/c\/";
        sed -i  "s/$src/$dst/g"  $1
        echo " ------------    acabado  -----------------------";
    else
        echo " ----- No hacemos nada con el yml, no estamos en docker"
    fi
}

#Paramos los anteriors
#docker-compose -f ./stack_definitions/config_generada/$compose_salida_integracion down

pushd mockservers_images
    ./build_mock_servers.sh
popd
rc=$?

if [[ $rc -eq 0 ]] ; then
    echo "--- Creamos configuracion con "
    echo "-----------------------------------"
    env | grep DOCKER
    echo "-----------------------------------"

    pushd ./stack_definitions/
        rm "./config_generada/$compose_salida_integracion"
        echo "-- Concatenamos composes para ($DOCKER_STACK_VERSION) $ADDITIONAL_COMPOSES"
        command_config=$(calculate_compose_components . "$ADDITIONAL_COMPOSES" "$compose_salida_integracion")
        echo "---      Creamos config con $command_config"
        eval $command_config

        arraglaYMLDockerBesideDoccker  "$(pwd)/config_generada/$compose_salida_integracion"

        arreglaPathsWindowsLinux  "$(pwd)/config_generada/$compose_salida_integracion"

        echo "--- Lanzamos compose ./config_generada/$compose_salida_integracion"
        docker-compose -f ./config_generada/$compose_salida_integracion up
        rc=$?
        echo "--- Lanzado compose ./config_generada/$compose_salida_integracion"
    popd
fi

if [[ $rc -ne 0 ]] ; then
    echo FAIL inicializando contexto de mock servers
    pushd ./stack_definitions/
        docker-compose  -f ./config_generada/$compose_salida_integracion down
    popd
else
    echo "--- Levantado entorno de aceptacion"
fi

exit $rc
