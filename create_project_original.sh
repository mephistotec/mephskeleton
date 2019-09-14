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

function reemplazaS3Credentials
{
    echo "reemplazamos credentials $1"
    echo "-------------------"
    export patternCollection=$1
    case "$(uname -s)" in

       Darwin)
         echo 'Replaces macos'
         fgrep -Rl "#cicd.sysops.s3.deploy#" . | while read file; do echo "Actualizando $file....."; sed -i '' "s/#cicd\.sysops\.s3\.deploy#/$patternCollection/g" $file; done
         ;;
       *)
         echo 'Replaces linux'
         fgrep -Rl "#cicd.sysops.s3.deploy#" . | while read file; do echo "Actualizando $file....."; sed -i  "s/#cicd\.sysops\.s3\.deploy#/$patternCollection/g" $file; done
         ;;
    esac
}

function reemplazaDomain
{
    echo "reemplazamos $1"
    echo "-------------------"
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
    echo "buildKubernetesTemplates $k8sfolder";
    mkdir -p $k8sfolder
    echo "buildKubernetesTemplates $3";
    if [[ $3 = *"DOCKER"* ]]; then
        echo "buildKubernetesTemplates aplicamos";
        aplicaciones="restapi engine full";
        echo "procesnando aplicaciones kubernetes";
        ls ../k8s_templates | while read fichero;
        do
            echo "------- PROCESANDO FICHERO $fichero --------------"
            for aplicacion in $aplicaciones; do
                echo "------- PROCESANDO aplicacion $aplicacion --------------"
                echo "procesnando aplicaciones $aplicacion";
                echo "Procesando template kubernetes $fichero para $k8sfolder/$aplicacion_$fichero";
                name="$1-$aplicacion"
                repo="mango\/$2\/$1-$aplicacion"
                request_cpu_value=1
                limit_cpu_value=1
                requests_memory_value=256m
                limit_memory_value=384m
                if [[ "$aplicacion" = "full" ]]; then
                    name=$1
                    repo="mango\/$2\/$1"
                    requests_memory_value=512m
                    limit_memory_value=640m
                elif [[ "$aplicacion" = "engine" ]]; then
                    requests_memory_value=512m
                    limit_memory_value=640m
                elif [[ "$aplicacion" = "restapi" ]]; then
                    requests_memory_value=384m
                    limit_memory_value=512m
                fi
                echo "Aplicamos $name $repo en $(pwd)  y  $k8sfolder/$aplicacion_$fichero"
                cat "../k8s_templates/$fichero" |
                        sed "s/<limit_cpu_value>/<limit_cpu_value_$aplicacion>/g" |
                        sed "s/<limit_memory_value>/<limit_memory_value_$aplicacion>/g" |
                        sed "s/<request_cpu_value>/<request_cpu_value_$aplicacion>/g" |
                        sed "s/<env_java_opts>/<env_java_opts_$aplicacion>/g" |
                        sed "s/<request_memory_value>/<request_memory_value_$aplicacion>/g" |
                        sed "s/<name>/$name/g" |
                        sed "s/<repo-name>/$repo/g" > $k8sfolder/$aplicacion\_$fichero;
            done
        done
    fi
}

function calculaFicherosKubernetesFinales
{
    echo "Unificando descriptores $(pwd) ..... "
    export k8sfolder="./$1/infrastructure/k8s";
    ls ../k8s_templates | while read fichero;
    do
        echo "Unificando descriptores - $k8sfolder/*_$fichero en $k8sfolder/$fichero - "
        ls $k8sfolder/*_$fichero | while read fichero_objeto;
        do
            echo "Unificando descriptores - $fichero_objeto en $k8sfolder/$fichero - "
            cat $fichero_objeto >> $k8sfolder/$fichero
            echo "---" >> $k8sfolder/$fichero
        done
        echo "Unificando descriptores limpiamos - $k8sfolder/*_$fichero - "
        rm $k8sfolder/*_$fichero
    done
}


#
# Aceptamos -f / --flags para inicializar opciones de generacion definidas en fichero environment_scripts/opt_<opcion>.sh
# Aceptamos -e / --env para inicializar variables en fichero environment_scripts/env_<opcion>.sh
# Aceptamos -v / --verison para seleccionar la versiónque queremos generar
echoerr "PARAMETROS ENV $@"

OPTS=$(getopt "-o f:e: -l flags:env:" -- $@)

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

echoerr "--- Inicializamos opciones y entornos con params $OPTS"

while true; do
  case "$1" in
    -f | --flags )
        echo "Setting flag $2"
        FLAG_PIPELINE=$2;
        option_filename="./environment_scripts/opt_$2.sh";
        if [ ! -f  $option_filename ];
        then
            echoerr "ERROR : No existe $option_filename";
            exit -1;
        fi
        echoerr "====> inicializando opt [$2] --> $option_filename";
        eval ". $option_filename";
        shift;shift ;;

    -v | --version )
        export DOCKER_STACK_VERSION=$2;
        shift;shift ;;
    -e | --env )
        ENTORNO_PIPELINE=$2
        echo "Setting entorno $2"
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done


export MAVEN_SETTINGS="--settings $(pwd)/settings.xml"
echo "--------- SETTINGS ------------"
echo $MAVEN_SETTINGS
echo "------------------------------"
 pushd mephskeleton
   pwd
   echo "---------------- LIMPIANDO CONTEXTO -------------------"
   mvn $MAVEN_SETTINGS clean install
   echo "---------------- CREANDO ARCHETYPE --------------------"
   mvn $MAVEN_SETTINGS  archetype:create-from-project
   echo "---------------- INSTALANDO ARCHETYPE -----------------"
   pushd target/generated-sources/archetype
     mvn $MAVEN_SETTINGS  install
   popd
 popd
 rm -fR ./built_project
 mkdir built_project
pushd built_project
  echo "---------------- CREANDO PROYECTO -------------"
  rm *.zip
   mvn archetype:generate \
       -DarchetypeGroupId=com.meph.mephskeleton \
       -DarchetypeArtifactId=mephskeleton-archetype \
       -DarchetypeVersion=RELEASE-INT-SNAPSHOT \
       -DgroupId=$1 -DartifactId=$2 -Dversion=RELEASE-INT-SNAPSHOT\
       -DarchetypeRepository=../mephskeleton/target/generated-sources/archetype/ \
       -DinteractiveMode=false
  echo "---------------- Ultimos retoques -------------"
  cp -R ../mephskeleton/build_pipeline/* $2/build_pipeline/
  mkdir -p $2/jenkinsfile_parts
  cp -R ../mephskeleton/jenkinsfile_parts/* $2/jenkinsfile_parts
  echo "---------------- Incorporamos kubernetes si toca ---------------"
  buildKubernetesTemplates $2 $5 $8
  echo "---------------- y el .gitignore -------------"
  cp ../mephskeleton/.gitignore $2/

  echo "---------------- REEMPLAZAMOS NOMBRE PROYECTO [$2] -------------"
  reemplazaNombres $2

  echo "---------------- REEMPLAZAMOS COLLECTION / REGISTRY [$5] -------------"
  reemplazaDomain $5

  echo "---------------- REEMPLAZAMOS USER JENKINS [$6] -------------"
  reemplazaJenkinsCredentials $6

  echo "---------------- REEMPLAZAMOS USER S3 [$7] -------------"
  reemplazaS3Credentials $7

  echo "---------------- REEMPLAZAMOS REPOS GIT [$9] [$10]----------------"
  reemplazaRepoGit $9 $10

  echo "---------------- ACTUALIZAMOS PERMISOS -------------"
  find . -name "*.sh" | while read file; do chmod 744 $file; done
  chmod 744 ./$2/build_pipeline/*.sh
  chmod 744 ./$2/jenkins_tasks/*.sh

  pushd $2

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
  #calculaFicherosKubernetesFinales $2

popd

echo "Jenkins files generation [$(pwd)][$2][$8]"

. ./generaJenkinsFiles.sh $2 $8

echo "Jenkins files generated [$(pwd)][$2][$8]"


 pushd built_project
       zip -r $2.zip ./$2
       #rm -R $2
 popd