#!/bin/bash

GROUPID=com.meph
NAMESPACE=mephnamespace
BASEDNSDOMAIN=meph.com
#JENKINS_CREDENTIALS=jenkins.cicd.user
#APPLICATION_TYPE=micro
PACKAGE=com.meph
BITBUCKETUSER=
BITBUCKETPASS=
BITBUCKETTEAM=
BITBUCKETPROJECTKEY=
BITBUCKETURL="https://api.bitbucket.org/2.0/repositories"
BITBUCKETFIRSTCOMMIT="Repo creation"
RESCODE=0
JENKINSURL=http://jenkins.meph.com/

if [ "$#" -lt 2 ]; then
  echo -e "Only  $# params. Use: create_project.sh  <artifcatid> <package for your classes>"
  echo -e "\t-g or --groupid\tsets the group id of your maven project , default: $GROUPID"
  echo -e "\t-r or -docker_registry\tregistry domain name to push images,"
  echo -e "\t\tyou can manage it in build_pipeline/00_env_pipeline.sh when artifact is generated "
  echo -e "\t-ns or --namespace\tNamespace for your kubernetes elements, default: $NAMESPACE"
  echo -e "\t-dns or --dnsbasename\tdns base name for your applications, default: $BASEDNSDOMAIN"
  echo -e "\t-bbuser or --bitbucket_username\tusername to create repository in bitbucket"
  echo -e "\t-bbpass or --bitbucket_password\t[optional] password to create repository in bitbucket"
  echo -e "\t-bbteam or --bitbucket_team\towner team for the repository"
  echo -e "\t-bbprojectkey or --bitbucket_project_key\tproject key to create repository in bitbucket"
#  echo -e "   -jc | --jenkins_credentials jenkins credentials ID to use in your jenkins tasks, default $JENKINS_CREDENTIALS"
#  echo -e "   -app | --application_type appliction type micro | worker | full (worker + micro), default : $APPLICATION_TYPE"
  exit -1
fi

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
            echo "Wrong application type, it should be full|micro|worker";
            exit -1;
        fi
        APPLICATION_TYPE=$2
        shift;shift ;;
    -bbuser | --bitbucket_username )
        BITBUCKETUSER=$2
        shift;shift ;;
    -bbpass | --bitbucket_password )
        BITBUCKETPASS=$2
        shift;shift ;;
    -bbprojectkey | --bitbucket_project_key )
        BITBUCKETPROJECTKEY=$2
        shift;shift ;;
    -bbteam | --bitbucket_team )
        BITBUCKETTEAM=$2
        shift;shift ;;
    -- ) shift ;;
    * ) break ;;
  esac
done


shift $(($OPTIND - 1))
ARTIFACTID=$1

function echoerr
{
  echo "[ERROR] $@" 1>&2;
}

function createBitbucketProjectIfNeeded
{
  pushd built_project
    pushd $ARTIFACTID
      bitbucketcred=
      if [ "$BITBUCKETUSER" != "" ]
      then
        if [ "$BITBUCKETPASS" != "" ]
        then
          bitbucketcred=$BITBUCKETUSER:$BITBUCKETPASS
        else
          bitbucketcred=$BITBUCKETUSER
        fi
        if [ "$BITBUCKETTEAM" != "" ] && [ "$BITBUCKETPROJECTKEY" != "" ];
        then
          command="curl -s -X POST  -u $bitbucketcred $BITBUCKETURL/$BITBUCKETTEAM/$ARTIFACTID -H \"Content-Type: application/json\"  -d '{\"has_wiki\": true, \"is_private\": true, \"project\": {\"key\": \"$BITBUCKETPROJECTKEY\"}}'"
          result=$(eval "$command")
          remote_url=$(echo $result | jq -r ".links.clone[0].href")
          echo "   Pushing to repository '$remote_url'"

          if [ "" = "$remote_url" ]
          then 
              echoerr "Error creating repo";
              RESCODE=-1;
          else
              if [ "null" = "$remote_url" ]
              then 
                  echoerr "Error creating repo";
                  RESCODE=-1;
              fi
          fi;

          if [[ $RESCODE -ne 0 ]] ; then
            echoerr "Due to errors in repo creation we cannot push your code"
          else
            git init
            if [[ $rc -eq 0 ]] ; then git add .; fi
            if [[ $rc -eq 0 ]] ; then git commit -m "$BITBUCKETFIRSTCOMMIT"; fi
            if [[ $rc -eq 0 ]] ; then git remote add origin "$remote_url"; fi
            if [[ $rc -eq 0 ]] ; then git remote -v; fi
            if [[ $rc -eq 0 ]] ; then git push -u origin master; fi
            #if [[ $rc -eq 0 ]] ; then git checkout -b develop; fi
            #if [[ $rc -eq 0 ]] ; then git push --set-upstream origin develop; fi
            RESCODE=$rc
          fi
        fi
      fi
    popd
  popd
}


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
    rm -fR *$1
    cat pom.xml | grep -vi $2 > pom2.xml
    rm pom.xml
    mv pom2.xml pom.xml
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

function replaceAll
{
      echo "Replacing names $1 $2"
        export patternReplace=$(echo "$1" | sed 's/\./\\\./g')
        export patternCollection=$(echo "$2" | sed 's/\./\\\./g')
        case "$(uname -s)" in
    
           Darwin)
             echo '  MacoS replace'
             fgrep -Rl $patternReplace . | while read file; do echo "Modifying $file....."; sed -i '' "s/$patternReplace/$patternCollection/g" $file; done
             ;;
           *)
             echo '  Linuz replaces'
             fgrep -Rl $patternReplace . | while read file; do echo "Modifying $file....."; sed -i  "s/$patternReplace/$patternCollection/g" $file; done
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


# function buildKubernetesTemplates
# {
#     export k8sfolder="./$1/infrastructure/k8s";
#     echo "   Building kubernetes templates in [$k8sfolder]";
#     mkdir -p $k8sfolder
#     echo "   Building applications template ...";
#     aplicaciones="restapi engine";
#     echo "   Iterating throug pods ...";
#     ls ../k8s_templates | while read fichero;
#     do
#         echo "   Processing descriptor $fichero"
#         for aplicacion in $aplicaciones; do
#             echo "   Building descriptor $fichero for $aplicacion ..."
#             echo "   Writing kubernetes $fichero in $k8sfolder/$aplicacion_$fichero";
#             name="$1-$aplicacion"
#             repo="$1-$aplicacion"
#             registryDomain="$2"
#             namespace="$3"
#             dnsbasename="$4"
#             echo "   Applying  $name $repo in $(pwd)  and $k8sfolder/$aplicacion_$fichero"
#             cat "../k8s_templates/$fichero" |
#                     sed "s/<limit_cpu_value>/<limit_cpu_value_$aplicacion>/g" |
#                     sed "s/<limit_memory_value>/<limit_memory_value_$aplicacion>/g" |
#                     sed "s/<request_cpu_value>/<request_cpu_value_$aplicacion>/g" |
#                     sed "s/<env_java_opts>/<env_java_opts_$aplicacion>/g" |
#                     sed "s/<request_memory_value>/<request_memory_value_$aplicacion>/g" |
#                     sed "s/<name>/$name/g" |
#                     sed "s/<namespace>/$namespace/g" |
#                     sed "s/<docker-registry-domain-name>/$registryDomain/g" |
#                     sed "s/<dnsbasename>/$dnsbasename/g" |
#                     sed "s/<aplication-repo-name>/$repo/g" > $k8sfolder/$aplicacion\_$fichero;
#         done
#     done
#     echo "   ---------------------------------------------------------------------"
#     echo "   IMPORTANT "
#     echo "   Customized k8s templates. You cant manage your request and limit "
#     echo "   resources editing your configuration script. Default values have been set."
#     echo "   ---------------------------------------------------------------------"
# }

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


function buildprojectFromArchetype
{
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

    #echo "Preparing kubernetes descriptors ..."
    #buildKubernetesTemplates $ARTIFACTID $DOCKERREGISTRYDOMAINNAME $NAMESPACE $BASEDNSDOMAIN
    echo "Adding .gitignore \( guessing you're using git, if not, you can clean it..."
    cp ../mephskeleton/.gitignore $ARTIFACTID/
  popd
}

function replaceNamesInBuiltProject
{
  pushd built_project
    echo "Replacing namespace where needed ..."
    replaceAll "mephnamespace" $NAMESPACE

    echo "Replacing domain where needed ..."
    replaceAll "#BASEDNSDOMAIN#" "$BASEDNSDOMAIN"

    echo "Replacing artifactid where needed ..."
    replaceAll "mephskeleton" $ARTIFACTID

    echo "Applying gesistry [$DOCKERREGISTRYDOMAINNAME] ..."
    if [ "$DOCKERREGISTRYDOMAINNAME" == "" ]; then
      echo "WARN : Docker repository not defined, you'll have to edit build_pipeline/00_env_pipeline.sh to set it!!!"
    else
      replaceDomain $DOCKERREGISTRYDOMAINNAME
    fi

    #echo "Setting jenkins credentials to [$JENKINS_CREDENTIALS]"
    #reemplazaJenkinsCredentials $JENKINS_CREDENTIALS

    echo "Adding permissions for shell scripts..."
    find . -name "*.sh" | while read file; do chmod 744 $file; done
    chmod 744 ./$ARTIFACTID/build_pipeline/*.sh
    chmod 744 ./$ARTIFACTID/jenkins_tasks/*.sh
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
        #if [  "$APPLICATION_TYPE" = "worker" ]; then
        #  cleanModules restapiApp restapiapp restapi
        #fi
    popd
  popd
}

echo "Preparing service for artifact $1"

#buildprojectFromArchetype
#replaceNamesInBuiltProject
createBitbucketProjectIfNeeded

#echo "Jenkins files generation \[$(pwd)\]\[$ARTIFACTID\]\[$8\]"
#. ./generaJenkinsFiles.sh $ARTIFACTID $8
#echo "Jenkins files generated \[$(pwd)\]\[$ARTIFACTID\]\[$8\]"

#pushd built_project
#  zip -r $ARTIFACTID.zip ./$ARTIFACTID
#popd