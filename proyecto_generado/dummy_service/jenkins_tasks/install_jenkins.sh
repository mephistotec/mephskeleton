#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
  echo "Only  $# params. Use: install_jenkins.sh <url_jenkins> <project_name> <base_jenkins_folder>"
  exit -1
fi


URL_JENKINS=$1
PROJECT_NAME=$2
BASE_FOLDER="$3/"

if [ "$BASE_FOLDER" = "/" ]; then
  BASE_FOLDER=""
fi

wget $URL_JENKINS/jnlpJars/jenkins-cli.jar -O jenkins-cli.jar

PROTOCOL=$(echo $URL_JENKINS | cut -d":" -f1)
URL=$(echo $URL_JENKINS | cut -d"/" -f3-)
JENKINS_URL=$PROTOCOL://$CICD_USER:$CICD_PASS@$URL

echo "... TRABAJAMOS CON [$PROTOCOL] [$URL][$PROJECT_NAME] [$JENKINS_URL]"

echo "java -jar jenkins-cli.jar -s $JENKINS_URL create-job $BASE_FOLDER$PROJECT_NAME  < ./folder/dummy_service.xml"
java -jar jenkins-cli.jar -s $JENKINS_URL create-job $BASE_FOLDER$PROJECT_NAME  < ./folder/dummy_service.xml

ls ./tasks | while read task ; do echo "---- PROCESANDO $task -----" ;  TASK_NAME=$(echo $task | cut -d"." -f 1); echo "----- CREAMOS TASK $TASK_NAME [java -jar jenkins-cli.jar -s $JENKINS_URL create-job $BASE_FOLDER$PROJECT_NAME/$TASK_NAME  < ./tasks/$task]";java -jar jenkins-cli.jar -s $JENKINS_URL create-job $BASE_FOLDER$PROJECT_NAME/$TASK_NAME  < ./tasks/$task;done;

