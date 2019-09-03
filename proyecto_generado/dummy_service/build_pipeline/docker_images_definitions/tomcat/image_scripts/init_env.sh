#!/bin/bash
if [ -f /run/secrets/mngpatilleditor_bbdd_PASSWORD_SECRET ];
then
    export MODEL_DATASOURCE_PASSWORD=$(cat /run/secrets/mngpatilleditor_bbdd_PASSWORD_SECRET)
fi
cd /usr/local/tomcat/bin
./catalina.sh run
