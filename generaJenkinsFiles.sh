#!/bin/bash

function generateJenkinsFiles
{
    nombre_artefacto=$1
#    tipo_artefacto_servicios=$2
    tipo_despliegue=$2

    echo "----------------------------------------------------"
    echo "Generando jenkinsfiles para [$(pwd)][$nombre_artefacto][$tipo_despliegue]"
    echo "----------------------------------------------------"

     prefixPipeFiles=./jenkinsfile_parts

     echo "validamos ./$nombre_artefacto/jenkinsfile_parts"

    if [ -d "./$nombre_artefacto/jenkinsfile_parts" ]; then

        pushd $nombre_artefacto

            rm Jenkinsfile
            rm Jenkinsfile-test

            echo "-- Creamos base de Jenkinsfile en $(pwd)  --> $prefixPipeFiles/00_Jenkinsfile_init > Jenkinsfile-test"
            cat $prefixPipeFiles/00_Jenkinsfile_init > Jenkinsfile
            cat $prefixPipeFiles/02_Jenkinsfile_sonar >> Jenkinsfile
            cat $prefixPipeFiles/00_Jenkinsfile_init > Jenkinsfile-test
            # Tenemos test de integraicon, genermaos imahenes
            echo "Check 1.0 [$(pwd)][./$nombre_artefacto-restapiApp] [./$nombre_artefacto-engineApp] [./$nombre_artefacto-singleApp]"
            if [ -d "./$nombre_artefacto-restapiApp" ] || [ -d "./$nombre_artefacto-engineApp" ] || [ -d "./$nombre_artefacto-singleApp" ]; then
                echo "-- Incorporamos imagenes y tests de integracion"
                echo "" >> Jenkinsfile
                cat $prefixPipeFiles/03_Jenkinsfile_docker_image_build >> Jenkinsfile
                cat $prefixPipeFiles/03_Jenkinsfile_docker_image_build >> Jenkinsfile-test
                cat $prefixPipeFiles/04_Jenkinsfile_docker_integration_test >> Jenkinsfile
            fi;

            echo "check \"$tipo_despliegue\" != *\"WDPRE\"*"

            if [[ $tipo_despliegue = *"WDPRE"* ]]; then
                echo "-- Incorporamos WDPRE"
                echo "" >> Jenkinsfile
                cat $prefixPipeFiles/05_Jenkinsfile_deploy_to_wdpre_pre >> Jenkinsfile
                echo "" >> Jenkinsfile-test
                cat $prefixPipeFiles/05_Jenkinsfile_deploy_to_wdpre_test >> Jenkinsfile-test
            fi

            if [[ $tipo_despliegue = *"DOCKER"* ]]; then
                echo "-- Incorporamos docker"
                echo "" >> Jenkinsfile
                cat $prefixPipeFiles/05_Jenkinsfile_deploy_to_docker_pre >> Jenkinsfile
                echo "" >> Jenkinsfile-test
                cat $prefixPipeFiles/05_Jenkinsfile_deploy_to_docker_test >> Jenkinsfile-test
            fi

            if [[ $tipo_despliegue = *"LSDOMAINS"* ]]; then
                echo "-- Incorporamos lsdomains"
                echo "" >> Jenkinsfile
                cat $prefixPipeFiles/05_Jenkinsfile_deploy_to_lsdomains_pre >> Jenkinsfile
                echo "" >> Jenkinsfile-test
                cat $prefixPipeFiles/05_Jenkinsfile_deploy_to_lsdomains_test >> Jenkinsfile-test
            fi

            echo "-- Incorporamos smoke test"
            echo "" >> Jenkinsfile
            cat $prefixPipeFiles/06_Jenkinsfile_smoke_test_pre >> Jenkinsfile
            cat $prefixPipeFiles/06_Jenkinsfile_smoke_test_test >> Jenkinsfile-test


            cat $prefixPipeFiles/99_Jenkinsfile_end >> Jenkinsfile
            cat $prefixPipeFiles/99_Jenkinsfile_end >> Jenkinsfile-test

            echo "Limpiamos informacion temporal de jenkinsfile"
            rm -R $prefixPipeFiles/*
            rmdir $prefixPipeFiles

        popd
    else
        echo "NO SE PUEDE GENERAR LA INFRAESTRUCTURA DE JENKINS FILE !!!!"
        exit -1
    fi

    echo "----------------------------------------------------"
}

echo "-------- Jenkinsfiles generation (init) -------------------"
pushd proyecto_generado
    generateJenkinsFiles $1 $2
popd
