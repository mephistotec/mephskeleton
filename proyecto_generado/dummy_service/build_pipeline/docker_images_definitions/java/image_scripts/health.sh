#!/usr/bin/env bash
echo "--- Ejecutando health -----"
#status=$(curl --fail -s localhost:8080/health | jq .status); if [ "$status" == "\"UP\"" ]; then exit 0; else exit 1; fi

wget --tries=1 --spider "http://localhost:8080/health"

rc=$?
if [[ $rc -ne 0 ]] ; then
   echo "Error en health de dockerfile : $rc"; exit $rc
fi
