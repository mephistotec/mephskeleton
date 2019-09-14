#!/bin/bash
if [ "$#" -lt 10 ]; then
  echo "Only  $# params. Use: create_full_project.sh <groupid> <artifcatid> <package> <FULL|MICROSERVICE|SINGLEWAR|ENGINE> <domain> <jenkins_credentials> <s3_credentials> [<DOCKER|LSDOMAINS|DOCKER_WDPRE|LSDOMAINS_WDPRE>] "
  echo " \$1 - groupid - group id para el artefacto"
  echo " \$2 - artifcatid - artifcat id para el artefacto"
  echo " \$3 package - package para las clases del artefacto"
  echo " -- \$4 (type of application) --"
  echo " FULL : Despliega restApiApp y engineApp"
  echo " MICROSERVICE : Despliega restApiApp"
  echo " ENGINE : despliega solo engine"
  echo " --"
  echo " \$5 domain : Collection docker donde desplegar (UCP)(p.e. #REGISTRY_DOMAIN_NAME#)"
#  echo " registryrepo : Repository for registry images"
  echo " \$6 jenkins_credentials : ID de credenciales Jenkins a usar en Jenkinsfile"
  echo " \$7 s3_credentials : ID de credenciales Jenkins a usar en Jenkinsfile para acceso a S3 (si aplica)"
  echo " -- \$8 (enviroment for application) --"
  echo "DOCKER_WDPRE entorno de deploy docker + wdpre"
  echo " -- \$9 (repogit en formato jira.mangodev.net/stash/scm/sb/mephskeleton.git sin https) --"
  echo " -- \$10 (repogit bitbucket web url en formato jira.mangodev.net/stash/projects/SB/repos/mephskeleton sin https) --"
  exit -1
fi

function limpia
{

  echo "limpiamos $1 en $(pwd)"
  echo "limpiamos $2 en pom"
  echo "limpiamos $3_* en $(pwd)"
  echo "-------------------"
  if [ "$3" != "" ]; then
    pwd
    ls -R ./infrastructure/k8s/$3*
    rm -fR ./infrastructure/k8s/$3*
  fi
  if [ "$1" != "" ]; then
    rm -fR *$1
    cat pom.xml | grep -vi $2 > pom2.xml
    rm pom.xml
    mv pom2.xml pom.xml
    rm ./build_pipeline/mockservers_images/docker_newman_image/test_integracion_scripts/POSTMAN*$2*
  fi
  echo "-------------------"
}

function reemplazaNombres
{
      echo "reemplazamos $1"
      echo "-------------------"
    export patternCollection=$(echo "$1" | sed 's/\./\\\./g')
    case "$(uname -s)" in

       Darwin)
         echo 'Replaces macos'
         fgrep -Rl mephskeleton . | while read file; do echo "Actualizando $file....."; sed -i '' "s/mephskeleton/$patternCollection/g" $file; done
         ;;
       *)
         echo 'Replaces linux'
         fgrep -Rl mephskeleton . | while read file; do echo "Actualizando $file....."; sed -i  "s/mephskeleton/$patternCollection/g" $file; done
         ;;
    esac
}

function reemplazaJenkinsCredentials
{
    echo "reemplazamos credentials $1"
    echo "-------------------"
    export patternCollection=$1
    case "$(uname -s)" in

       Darwin)
         echo 'Replaces macos'
         fgrep -Rl "#jenkins.credentials.id#" . | while read file; do echo "Actualizando $file....."; sed -i '' "s/#cicd\.sysops#/$patternCollection/g" $file; done
         ;;
       *)
         echo 'Replaces linux'
         fgrep -Rl "#jenkins.credentials.id#" . | while read file; do echo "Actualizando $file....."; sed -i  "s/#cicd\.sysops#/$patternCollection/g" $file; done
         ;;
    esac
}

function reemplazaDomain
{
    echo "Applying registry [$1]"
    echo "----------------------"
    patternCollection=$1
    patternCollection=$(echo $patternCollection | sed 's/\//\\\//g')
    patternRegistry=$2
    patternRegistry=$(echo $patternRegistry | sed 's/\//\\\//g')

    echo "------queda $patternCollection -------------"

    case "$(uname -s)" in

       Darwin)
         echo 'Replaces macos'
         fgrep -Rl "=#REGISTRY_DOMAIN_NAME#" . | while read file; do echo "Actualizando $file....."; sed -i '' "s/=#REGISTRY_DOMAIN_NAME#/=$patternCollection/g" $file; done
         ;;
       *)
         echo 'Replaces linux'
         fgrep -Rl "=#REGISTRY_DOMAIN_NAME#" . | while read file; do echo "Actualizando $file....."; sed -i  "s/=#REGISTRY_DOMAIN_NAME#/=$patternCollection/g" $file; done
         ;;
    esac
}


function reemplazaRepoGit
{
    echo "reemplazamos $1"
    echo "-------------------"
    repoGit=$1
    repoGit=$(echo $repoGit | sed 's/\//\\\//g'| sed 's/\./\\./g')
    repoGitBitbucketUrl=$2
    repoGitBitbucketUrl=$(echo $repoGitBitbucketUrl | sed 's/\//\\\//g' | sed 's/\./\\./g')

    echo "------queda $patternCollection -------------"

    case "$(uname -s)" in

       Darwin)
         echo 'Replaces macos'
         fgrep -Rl "<url_repo_git>" . | while read file; do echo "Actualizando $file....."; sed -i '' "s/<url_repo_git>/=$repoGit/g" $file; done
         ;;
       *)
         echo 'Replaces linux'
         fgrep -Rl "<url_repo_git>" . | while read file; do echo "Actualizando $file....."; sed -i  "s/<url_repo_git>/=$repoGit/g" $file; done
         ;;
    esac

    case "$(uname -s)" in

       Darwin)
         echo 'Replaces macos'
         fgrep -Rl "<url_web_repo_git>" . | while read file; do echo "Actualizando $file....."; sed -i '' "s/<url_web_repo_git>/=$repoGitBitbucketUrl/g" $file; done
         ;;
       *)
         echo 'Replaces linux'
         fgrep -Rl "<url_web_repo_git>" . | while read file; do echo "Actualizando $file....."; sed -i  "s/<url_web_repo_git>/=$repoGitBitbucketUrl/g" $file; done
         ;;
    esac

}

function buildKubernetesTemplates
{
    export k8sfolder="./$1/infrastructure/k8s";
    echo "   Building kubernetes templates in [$k8sfolder]";
    mkdir -p $k8sfolder
    echo "   Building applications template ...";
    aplicaciones="restapi engine";
    echo "   Iterating throug pods ...";
    ls ../k8s_templates | while read fichero;
    do
        echo "   Processing descriptor $fichero"
        for aplicacion in $aplicaciones; do
            echo "   Building descriptor $fichero for $aplicacion ..."
            echo "   Writing kubernetes $fichero in $k8sfolder/$aplicacion_$fichero";
            name="$1-$aplicacion"
            repo="$1-$aplicacion"
            registryDomain="$2"
            namespace="$3"
            dnsbasename="$4"
            echo "   Applying  $name $repo in $(pwd)  and $k8sfolder/$aplicacion_$fichero"
            cat "../k8s_templates/$fichero" |
                    sed "s/<limit_cpu_value>/<limit_cpu_value_$aplicacion>/g" |
                    sed "s/<limit_memory_value>/<limit_memory_value_$aplicacion>/g" |
                    sed "s/<request_cpu_value>/<request_cpu_value_$aplicacion>/g" |
                    sed "s/<env_java_opts>/<env_java_opts_$aplicacion>/g" |
                    sed "s/<request_memory_value>/<request_memory_value_$aplicacion>/g" |
                    sed "s/<name>/$name/g" |
                    sed "s/<namespace>/$namespace/g" |
                    sed "s/<docker-registry-domain-name>/$registryDomain/g" |
                    sed "s/<dnsbasename>/$dnsbasename/g" |
                    sed "s/<aplication-repo-name>/$repo/g" > $k8sfolder/$aplicacion\_$fichero;
        done
    done
    echo "   ---------------------------------------------------------------------"
    echo "   IMPORTANT "
    echo "   Customized k8s templates. You cant manage your request and limit "
    echo "   resources editing your configuration script. Default values have been set."
    echo "   ---------------------------------------------------------------------"
}

function calculaFicherosKubernetesFinales
{
    echo "   Unifying descriptors int $(pwd) ..... "
    export k8sfolder="./$1/infrastructure/k8s";
    ls ../k8s_templates | while read fichero;
    do
        echo "   Unifying - $k8sfolder/*_$fichero in $k8sfolder/$fichero - "
        ls $k8sfolder/*_$fichero | while read fichero_objeto;
        do
            echo "      Unifying - $fichero_objeto en $k8sfolder/$fichero - "
            cat $fichero_objeto >> $k8sfolder/$fichero
            echo "---" >> $k8sfolder/$fichero
        done
        echo "   Unified, cleaning $k8sfolder/*_$fichero - "
        rm $k8sfolder/*_$fichero
    done
}

echoerr "PARAMETROS ENV $@"

OPTS=$(getopt "-o f:e: -l flags:env:" -- $@)

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

echoerr "--- Inicializamos opciones y entornos con params $OPTS"

GROUPID=com.meph
ARTIFACTID=$1
NAMESPACE=mephapps
BASEDNSDOMAIN=k8s.meph.local
JENKINS_CREDENTIALS=jenkins.cicd.user

while true; do
  case "$1" in
    -g | --groupid )
        echo "Setting groupid $2"
        GROUP_ID=$2
        shift;shift ;;
    -r | --docker_registry )
        echo "Setting registry $2"
        DOCKERREGISTRYDOMAINNAME=$2
        shift;shift ;;
    -ns | --namespace )
        echo "Setting namespace $2"
        NAMESPACE=$2
        shift;shift ;;
    -dns | --dnsbasename )
        echo "Setting base dns domain $2"
        BASEDNSDOMAIN=$2
        shift;shift ;;
    -jc | --jenkins_credentials )
        echo "Setting jenkins credentials to $2"
        JENKINS_CREDENTIALS=$2
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done


# We could change maven settings but we don't
#export MAVEN_SETTINGS="--settings $(pwd)/settings.xml"
echo "Applying maven settings [$MAVEN_SETTINGS]"
 pushd mephskeleton
   pwd
   echo "Cleaning maven context ..."
   mvn $MAVEN_SETTINGS clean install
   echo "Creating archetype ..."
   mvn $MAVEN_SETTINGS  archetype:create-from-project
   echo "Installing archetype ..."
   pushd target/generated-sources/archetype
     mvn $MAVEN_SETTINGS  install
   popd
 popd
 echo "Cleaing project folder ..."
 rm -fR ./built_project
 mkdir built_project
 pushd built_project
  echo "Building project from archetype ..."
  rm *.zip
   mvn archetype:generate \
       -DarchetypeGroupId=com.meph.mephskeleton \
       -DarchetypeArtifactId=mephskeleton-archetype \
       -DarchetypeVersion=RELEASE-INT-SNAPSHOT \
       -DgroupId=$GROUPID -DartifactId=$ARTIFACTID -Dversion=RELEASE-INT-SNAPSHOT\
       -DarchetypeRepository=../mephskeleton/target/generated-sources/archetype/ \
       -DinteractiveMode=false
  echo "Now, what archetype does not do :) ..."
  echo "Copying pipeline ..."
  cp -R ../mephskeleton/build_pipeline/* $ARTIFACTID/build_pipeline/
  mkdir -p $ARTIFACTID/jenkinsfile_parts
  cp -R ../mephskeleton/jenkinsfile_parts/* $ARTIFACTID/jenkinsfile_parts

  echo "Preparing kubernetes descriptors ..."
  buildKubernetesTemplates $ARTIFACTID $DOCKERREGISTRYDOMAINNAME $NAMESPACE $BASEDNSDOMAIN
  echo "Adding .gitignore ( guessing you're using git, if not, you can clean it..."
  cp ../mephskeleton/.gitignore $ARTIFACTID/

  echo "Replacing artifactid where needed ..."
  reemplazaNombres $ARTIFACTID

  echo "Applying gesistry [$DOCKERREGISTRYDOMAINNAME] ..."
  if [ "$DOCKERREGISTRYDOMAINNAME" == "" ]; then
    echoerr "WARN : Docker repository not defined, you'll have to edit build_pipelin/00_env_pipeline.sh to set it!!!"
  else
    reemplazaDomain $DOCKERREGISTRYDOMAINNAME
  fi

  echo "Setting jenkins credentials to [$JENKINS_CREDENTIALS]"
  reemplazaJenkinsCredentials $JENKINS_CREDENTIALS

  echo "---------------- REEMPLAZAMOS REPOS GIT [$9] [$10]----------------"
  reemplazaRepoGit $9 $10

  echo "---------------- ACTUALIZAMOS PERMISOS -------------"
  find . -name "*.sh" | while read file; do chmod 744 $file; done
  chmod 744 ./$ARTIFACTID/build_pipeline/*.sh
  chmod 744 ./$ARTIFACTID/jenkins_tasks/*.sh

  pushd $ARTIFACTID

      echo "---------------- borramos temporales -------------"
      rm -Rf ./build_pipeline/tmp/*
      rm -Rf ./build_pipeline/stack_definitions/config_generada/*

      echo "---------------- borramos casa -------------"
      #rm ./build_pipeline/environment_scripts/*casa*

      echo "---------------- NORMALIZAMOS PROYECT -------------"
      # Nos petamos lo que toque segun el tipo de aplicación
      if [ "$4" = "FULL" ]; then
        echo "-- Montando proyecto $4"
        pwd
        ls -la
        echo "-------------------------------"
        limpia singleApp singleapp full
      fi
      if [ "$4" = "MICROSERVICE" ]; then
        echo "-- Montando proyecto $4"
        pwd
        ls -la
        echo "-------------------------------"
        limpia singleApp singleapp full
        limpia engineApp engineapp engine
      fi
      if [ "$4" = "SINGLEWAR" ]; then
        echo "-- Montando proyecto $4"
        pwd
        ls -la
        echo "-------------------------------"
        limpia engineApp engineapp engine
        limpia restapiApp restapiapp restapi
      fi
      if [ "$4" = "ENGINE" ]; then
        echo "-- Montando proyecto $4"
        pwd
        ls -la
        echo "-------------------------------"
        limpia restapiApp restapiapp restapi
        limpia singleApp singleapp full
      fi
      echo "Tipo de deploy ($8)"
      if [[ $8 = *"DOCKER"* ]]; then
        echo "-- Montando deploy $8"
        pwd
        ls -la ./jenkins_tasks/tasks/*lsdomains*
        echo "-------------------------------"
        rm ./jenkins_tasks/tasks/*lsdomains*
      fi
      if [[ $8 = *"LSDOMAINS"* ]]; then
        echo "-- Montando deploy $8"
        pwd
        ls -la ./jenkins_tasks/tasks/*docker*
        echo "-------------------------------"
        rm ./jenkins_tasks/tasks/*docker*
      fi
      if [[ $8 != *"WDPRE"* ]]; then
        echo "--  Quitando cosas de WDPRE por deploy $8"
        pwd
        ls -la ./jenkins_tasks/tasks/*wdpre*
        echo "-------------------------------"
        rm ./jenkins_tasks/tasks/*wdpre*
        echo "---------- limpiamos batch ---------------"
        limpia batch batch
      fi
  popd

  # No unificamos
  #calculaFicherosKubernetesFinales $ARTIFACTID

popd

echo "Jenkins files generation [$(pwd)][$ARTIFACTID][$8]"

. ./generaJenkinsFiles.sh $ARTIFACTID $8

echo "Jenkins files generated [$(pwd)][$ARTIFACTID][$8]"


 pushd built_project
       zip -r $ARTIFACTID.zip ./$ARTIFACTID
       #rm -R $ARTIFACTID
 popd