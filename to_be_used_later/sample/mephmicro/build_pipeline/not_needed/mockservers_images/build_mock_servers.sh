#!/usr/bin/env bash

echo "--- Creando mockserver de BBDD con"

pushd docker_bbdd_image

./build.sh

popd

echo "--- Creando mockserver de APIS - Necesitamos credenciales GIT para poder llevarlo a cabo"

pushd docker_mockapis_image

./build.sh $USER_GIT $PASS_GIT

popd


echo "--- Creando mnewman"

pushd docker_newman_image

./build.sh

popd

echo "--- Parece que tenemos las imagenes de servidores."
