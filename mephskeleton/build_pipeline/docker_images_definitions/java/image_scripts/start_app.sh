#!/bin/bash
#
#Esperamos que se definan en RUNTIME:
#
#- ACTIVE_PROFILES para determinar el profile de arranque de la JVM
#- ENV_JAVA_OPTS Configuraciones de requerimientos de memoria
#- $debugJava Indica si hemos de activar el modo debug
#
JAVA_OPTS="-Dspring.profiles.active=$ACTIVE_PROFILES"
JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -Duser.timezone=Europe/Madrid"

export MODEL_DATASOURCE_PASSWORD=$(cat /run/secrets/mephskeleton_bbdd_PASSWORD_SECRET)

echo Lanzamos con $JAVA_OPTS $ENV_JAVA_OPTS
java  $JAVA_OPTS $ENV_JAVA_OPTS -jar /data/$DESTINATION_JAR
