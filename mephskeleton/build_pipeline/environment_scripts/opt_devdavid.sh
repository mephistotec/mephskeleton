#!/usr/bin/env bash

# Mis credenciales
export CICD_USER=david.malaga
export CICD_PASS=Noddon003

# Usuario GIT
if [ -z "$CICD_USER" ];
then
    echo "Variable CICD_USER does not exist!";
    exit -1;
fi
if [ -z "$CICD_PASS" ];
then
    echo "Variable CICD_PASS does not exist!";
    exit -1;
fi

# Usuario GIT
export USER_GIT=$CICD_USER
export PASS_GIT=$CICD_PASS


# Inicializamos el path de credenciales (lo hacemos aqui para jenkins - No puede ser $HOME!!!)
export PATH_CREDENTIALS_AWS_LOCAL=/mnt/c/Users/David/.aws

#Docker Settings
export DOCKER_HOST=tcp://192.168.99.100:2376
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH=/c/Users/David/.docker/machine/certs

#Sonar settings
#export SONAR_USER=73b7103d5211a99d5e3c2bdf4095fd9c349bea7a
export SONAR_USER=admin
export SONAR_PASSWORD=admin
export SONAR_HOST_URL=http://192.168.99.100:9000

export SONAR_GOAL="org.codehaus.sonar:sonar"
export SONAR_GOAL="org.codehaus.sonar:sonar-maven3-plugin:2.2:sonar"
if [ "$SONAR_PASSWORD" == "" ];
then
    export SONAR_PARAMS="-Dsonar.login=$SONAR_USER -Dsonar.host.url=$SONAR_HOST_URL"
else
    export SONAR_PARAMS="-Dsonar.login=$SONAR_USER -Dsonar.password=$SONAR_PASSWORD -Dsonar.host.url=$SONAR_HOST_URL"
fi


