#!/usr/bin/env bash

#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# DOCKER_STACK_VERSION - Version a desplegar - si no se define -v <version> , la del POM
# DOCKER_REGISTRY_MNG_REPOSITORY - Repositorio al que subir las imagenes, se define con el -f <registrymng_pre> por ejemplo
# DOCKER_REGISTRY_MNG_USER - Usuario de acceso al registry
# DOCKER_REGISTRY_MNG_PASSWORD - password de acceso al registry
#
# necesita $ADDITIONAL_COMPOSES que se define en funcion de aplicaEntorno que se llame
#
# necesita de que se defina con -e <entorno> el entorno para el que se publican imagenes.
#--------------------------------------------------------------------------

if [ -d "../mephskeleton-batch" ]; then
    ./04_23_build_zip_wdpre.sh $@

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Building ZIP para wspre'; exit $rc
    fi

    ./04_24_push_zip_to_s3_wdpre.sh $@

    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- Pushing zip to S3'; exit $rc
    fi

    echo "Artifact in S3!!"
fi
