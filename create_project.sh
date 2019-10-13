#!/bin/bash

GROUPID=com.meph
NAMESPACE=mephapps
BASEDNSDOMAIN=k8s.meph.local
JENKINS_CREDENTIALS=jenkins.cicd.user
APPLICATION_TYPE=micro
PACKAGE=com.meph

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

ARTIFACTID=$1


function cleanModules
{

  echo "Cleaning $1 in $(pwd)"
  echo "Cleaning $2 in pom"
  echo "Cleaning $3_* en $(pwd)"
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

function replaceNames
{
      echo "Replacing names $1"
        export patternCollection=$(echo "$1" | sed 's/\./\\\./g')
        case "$(uname -s)" in
    
           Darwin)
             echo '  MacoS replace'
             fgrep -Rl mephskeleton . | while read file; do echo "Modifying $file....."; sed -i '' "s/mephskeleton/$patternCollection/g" $file; done
             ;;
           *)
             echo '  Linuz replaces'
             fgrep -Rl mephskeleton . | while read file; do echo "Modifying $file....."; sed -i  "s/mephskeleton/$patternCollection/g" $file; done
             ;;
        esac
}

function reemplazaJenkinsCredentials
{
    echo "Replacing credentials $1 ..."
    export patternCollection=$1
    case "$(uname -s)" in
       Darwin)
         echo 'MacoS replace'
         fgrep -Rl "#jenkins.credentials.id#" . | while read file; do echo "Modifying $file....."; sed -i '' "s/#cicd\.sysops#/$patternCollection/g" $file; done
         ;;
       *)
         echo 'Linuz replaces'
         fgrep -Rl "#jenkins.credentials.id#" . | while read file; do echo "Modifying $file....."; sed -i  "s/#cicd\.sysops#/$patternCollection/g" $file; done
         ;;
    esac
}

function replaceDomain
{
    echo "Applying registry [$1] ..."
    patternCollection=$1
    patternCollection=$(echo $patternCollection | sed 's/\//\\\//g')
    patternRegistry=$2
    patternRegistry=$(echo $patternRegistry | sed 's/\//\\\//g')

    echo "------queda $patternCollection -------------"

    case "$(uname -s)" in

       Darwin)
         echo '   MacoS replace'
         fgrep -Rl "=#REGISTRY_DOMAIN_NAME#" . | while read file; do echo "Modifying $file....."; sed -i '' "s/=#REGISTRY_DOMAIN_NAME#/=$patternCollection/g" $file; done
         ;;
       *)
         echo '   Linuz replaces'
         fgrep -Rl "=#REGISTRY_DOMAIN_NAME#" . | while read file; do echo "Modifying $file....."; sed -i  "s/=#REGISTRY_DOMAIN_NAME#/=$patternCollection/g" $file; done
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

function moveClassesToPackage
{
    PACKAGECLASS=$1
    ARTIFACTID=$2
    declare -a classesToMove=("./$ARTIFACTID-engineApp/src/main/java/EngineApp.java" "./$ARTIFACTID-restapiApp/src/main/java/RESTApp.java" )
    for pathOrigen in ${classesToMove[@]}; do
        echo "   processing $pathOrigen"
        if [ -f "$pathOrigen" ]; then
            echo -e "package $PACKAGECLASS;"  > "$pathOrigen\_v2"
            cat $pathOrigen  >> "$pathOrigen\_v2"
            mv "$pathOrigen\_v2" $pathOrigen
            echo "   added package $pathOrigen"
            packagepath=$(echo $PACKAGECLASS | sed "s/\./\//g")
            pathDestino="$(dirname $pathOrigen)/$packagepath";
            echo "   creating $pathDestino"
            mkdir -p $pathDestino
            echo "   moving to $pathDestino"
            mv $pathOrigen $pathDestino
        fi
    done
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

echo "Environment $@"

OPTS=$(getopt "-o f:e: -l flags:env:" -- $@)

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

eval set -- "$OPTS"

echo "Configuring selected options $OPTS"



while true; do
  case "$1" in
    -g | --groupid )
        echo "Setting groupid $2"
        GROUP_ID=$2
        shift;shift ;;
    -p | --package )
        echo "Setting package $2"
        PACKAGE=$2
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
    -app | --application_type )
        if [ "$2" = "full" ] || [ "$" = "micro" ] || [ "$" = "worker" ] ; then
            echo "Setting application type to $2"
        else
            echo "Wron application type, it should be full|micro|worker";
            exit -1;
        fi
        APPLICATION_TYPE=$2
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done

if [ "" == "" ]
then

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
       -DarchetypeVersion=DEVELOP-SNAPSHOT \
       -DgroupId=$GROUPID -DartifactId=$ARTIFACTID -Dversion=DEVELOP-SNAPSHOT\
       -DarchetypeRepository=../mephskeleton/target/generated-sources/archetype/ \
       -DinteractiveMode=false
  echo "Now, what archetype does not do :\) ..."
  echo "Copying pipeline ..."
  cp -R ../mephskeleton/build_pipeline/* $ARTIFACTID/build_pipeline/
  mkdir -p $ARTIFACTID/jenkinsfile_parts
  cp -R ../mephskeleton/jenkinsfile_parts/* $ARTIFACTID/jenkinsfile_parts

  echo "Preparing kubernetes descriptors ..."
  buildKubernetesTemplates $ARTIFACTID $DOCKERREGISTRYDOMAINNAME $NAMESPACE $BASEDNSDOMAIN
  echo "Adding .gitignore \( guessing you're using git, if not, you can clean it..."
  cp ../mephskeleton/.gitignore $ARTIFACTID/

  echo "Replacing artifactid where needed ..."
  replaceNames $ARTIFACTID

  echo "Applying gesistry [$DOCKERREGISTRYDOMAINNAME] ..."
  if [ "$DOCKERREGISTRYDOMAINNAME" == "" ]; then
    echo "WARN : Docker repository not defined, you'll have to edit build_pipeline/00_env_pipeline.sh to set it!!!"
  else
    replaceDomain $DOCKERREGISTRYDOMAINNAME
  fi

  echo "Setting jenkins credentials to [$JENKINS_CREDENTIALS]"
  reemplazaJenkinsCredentials $JENKINS_CREDENTIALS

  echo "Adding permissions for shell scripts..."
  find . -name "*.sh" | while read file; do chmod 744 $file; done
  chmod 744 ./$ARTIFACTID/build_pipeline/*.sh
  chmod 744 ./$ARTIFACTID/jenkins_tasks/*.sh

  else
   pushd built_project
  fi;

  pushd $ARTIFACTID

      echo "Cleaning temp files..."
      rm -Rf ./build_pipeline/tmp/*
      rm -Rf ./build_pipeline/stack_definitions/config_generada/*

      echo "Refactoring classes for package $PACKAGE..."
      moveClassesToPackage $PACKAGE $ARTIFACTID

      echo "Removing not needed components ..."
      # Nos petamos lo que toque segun el tipo de aplicación
      if [ "$APPLICATION_TYPE" = "micro" ]; then
        cleanModules engineApp engineapp engine
      fi
      if [  "$APPLICATION_TYPE" = "worker" ]; then
        cleanModules restapiApp restapiapp restapi
      fi
  popd
popd

echo "Jenkins files generation \[$(pwd)\]\[$ARTIFACTID\]\[$8\]"

#. ./generaJenkinsFiles.sh $ARTIFACTID $8

echo "Jenkins files generated \[$(pwd)\]\[$ARTIFACTID\]\[$8\]"

exit 0;
pushd built_project
   zip -r $ARTIFACTID.zip ./$ARTIFACTID
popd