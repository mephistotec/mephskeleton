#!/usr/bin/env bash

# Sobreescribimos para incorporar debug
export ENV_JAVA_OPTS_ENGINE="$ENV_JAVA_OPTS_ENGINE -agentlib:jdwp=transport=dt_socket,address=8091,server=y,suspend=n"
export ENV_JAVA_OPTS_RESTAPI="$ENV_JAVA_OPTS_RESTAPI -agentlib:jdwp=transport=dt_socket,address=8091,server=y,suspend=n"
export ENV_JAVA_OPTS_FULL="$ENV_JAVA_OPTS_FULL -agentlib:jdwp=transport=dt_socket,address=8091,server=y,suspend=n"

# incorporamos el password como secret
export MODEL_DATASOURCE_PASSWORD_SECRET=mephskeleton_bbdd_PASSWORD_SECRET

export ACTIVE_PROFILES=mock

export MODEL_DATASOURCE_USER="DB_INTEG_USER"
export MODEL_DATASOURCE_URL="jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=mephskeleton_bbddtest)(PORT=1521))(CONNECT_DATA=(service_name=xe)))"

# Additional composes - Composes que facilian en funcionamiento del stack en un determinado entorno.
if [ ! "$PATH_CREDENTIALS_AWS_LOCAL" == "" ];
then
    export ADDITIONAL_COMPOSES="docker-compose-local.yml docker-compose-mockservers.yml";
else
    export ADDITIONAL_COMPOSES=" docker-compose-mockservers.yml";
fi

# Composes por IMAGEN
if [ -d "../mephskeleton-restapiApp" ]; then
    export ADDITIONAL_COMPOSES="$ADDITIONAL_COMPOSES restapi/docker-compose-mockservers.yml"
fi;


if [ -d "../mephskeleton-engineApp" ]; then
    export ADDITIONAL_COMPOSES="$ADDITIONAL_COMPOSES engine/docker-compose-mockservers.yml"
fi

if [ -d "../mephskeleton-singleApp" ]; then
    export ADDITIONAL_COMPOSES="$ADDITIONAL_COMPOSES singleapp/docker-compose-mockservers.yml"
fi

#cifrado de pass / users
#export APP_ENC_CLASS="1234567890"
