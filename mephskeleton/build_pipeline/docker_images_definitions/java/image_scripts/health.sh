#!/usr/bin/env bash
echo "--- Ejecutando health -----"
wget --tries=1 --spider "http://localhost:8080/health"

rc=$?
if [[ $rc -ne 0 ]] ; then
   echo "Error en health de dockerfile : $rc"; exit $rc
fi
