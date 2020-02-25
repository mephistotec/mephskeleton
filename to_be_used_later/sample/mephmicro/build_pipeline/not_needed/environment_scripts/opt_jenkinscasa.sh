#!/usr/bin/env bash

# Usuario GIT
export CICD_USER=daniel.luque
export CICD_PASS=Mango234
# Usuario GIT
export USER_GIT=$CICD_USER
export PASS_GIT=$CICD_PASS

# Inicializamos el path de credenciales (lo hacemos aqui para jenkins - No puede ser $HOME!!!)
export PATH_CREDENTIALS_AWS_LOCAL=/Users/dani/.aws

#Sonar settings
#export SONAR_USER=73b7103d5211a99d5e3c2bdf4095fd9c349bea7a
export SONAR_USER=admin
export SONAR_PASSWORD=admin
export SONAR_HOST_URL=http://sonarqube:9000

export SONAR_GOAL="sonar:sonar"
if [ "$SONAR_PASSWORD" == "" ];
then
    export SONAR_PARAMS="-Dsonar.login=$SONAR_USER -Dsonar.host.url=$SONAR_HOST_URL"
else
    export SONAR_PARAMS="-Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASSWORD -Dsonar.host.url=$SONAR_HOST_URL"
fi


