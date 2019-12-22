#!/usr/bin/env bash

./create_project.sh $1

if [ "$#" -lt 2 ]; then
  echo "Only  $# params. Use: create_project.sh  <artifcatid> <package for your classes>"
  echo "   -g | --groupid sets the group id of your maven project , default: $GROUPID"
  echo "   -r | --docker_registry registry domain name to push images,"
  echo "                          you can manage it in build_pipeline/00_env_pipeline.sh when artifact is generated "
  echo "   -ns | --namespace Namespace for your kubernetes elements, default: $NAMESPACE"
  echo "   -dns | --dnsbasename dns base name for your applications, default: $BASEDNSDOMAIN"
  echo "   -jc | --jenkins_credentials jenkins credentials ID to use in your jenkins tasks, default $JENKINS_CREDENTIALS"
  echo "   -app | --application_type appliction type micro | worker | full (worker + micro), default : $APPLICATION_TYPE"
  exit -1
fi