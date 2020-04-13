#!/bin/bash
if [ "$#" -lt 1 ]; then
  echo -e "Only  $# params. Use: create_local_project.sh  <artifcatid>"
  exit -1
fi

. ./create_project.sh -r localhost:5000 -ns meph -bbuser daniel.luque@gmail.com -bbteam MEHISTOS -bbprojectkey TES $1 com.meph
