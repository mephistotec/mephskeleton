#!/usr/bin/env bash

#--------------------------------------------------------------------------
# Requiere que se definan las variables : paral el pull - push
#
# STACK_VERSION - Version a desplegar - si no se define -v <version> , la del POM
# DOCKER_REGISTRY_MNG_REPOSITORY - Repositorio al que subir las imagenes, se define con el -f <registrymng_pre> por ejemplo
# DOCKER_REGISTRY_MNG_USER - Usuario de acceso al registry
# DOCKER_REGISTRY_MNG_PASSWORD - password de acceso al registry
#
# necesita $ADDITIONAL_COMPOSES que se define en funcion de aplicaEntorno que se llame
#
# necesita de que se defina con -e <entorno> el entorno para el que se publican imagenes.
#--------------------------------------------------------------------------

./04_01_publish_images.sh $@

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error publishing images'; exit $rc
fi

./04_02_deploy_stack.sh $@

rc=$?
if [[ $rc -ne 0 ]] ; then
  echo '--- Error Desplegando stack'; exit $rc
fi

echo "Deploy complete!!!"