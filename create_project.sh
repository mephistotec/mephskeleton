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
GIT_REPO_URL=
JENKINSURL=
JENKINSAPICREDENTIALS=
JENKINSGITCREDENTIALS=

if [ "$#" -lt 2 ]; then
  echo -e "Only  $# params. Use: create_project.sh  <artifcatid> [OPTIONS]"
  echo -e "\t-g or --groupid\tsets the group id of your maven project , default: $GROUPID"
  echo -e "\t-r or -docker_registry\tregistry domain name to push images,"
  echo -e "\t\tyou can manage it in build_pipeline/00_env_pipeline.sh when artifact is generated "
  echo -e "\t-ns or --namespace\tNamespace for your kubernetes elements, default: $NAMESPACE"
  echo -e "\t-dns or --dnsbasename\tdns base name for your applications, default: $BASEDNSDOMAIN"
  echo -e "\t-bbuser or --bitbucket_username\tusername to create repository in bitbucket"
  echo -e "\t-bbpass or --bitbucket_password\t[optional] password to create repository in bitbucket"
  echo -e "\t-bbteam or --bitbucket_team\towner team for the repository"
  echo -e "\t-bbprojectkey or --bitbucket_project_key\tproject key to create repository in bitbucket"
  echo -e "\t-jurl or --jenkins_url key to create repository in bitbucket"
  echo -e "\t-japicred or --jenkins_api_cred\tCredentials for jenkins API user:API_TOKE"
  echo -e "\t-jgitcred or --jenkins_git_credentials_id\tCredentials id to use to access git."¡
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
        echo "Setting registry $2 "
        DOCKERREGISTRYURL=$2
        if [[ $2 == *"://"* ]]; then
          DOCKERREGISTRYDOMAINAME=$(echo $2 | cut -d"/" -f3-);
        else 
          DOCKERREGISTRYDOMAINAME=$2
        fi        
        echo "after setting registry $2 : $DOCKERREGISTRYURL / $DOCKERREGISTRYDOMAIN"
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
    -jurl | --jenkins_url )
        echo "jenkins url $2"
        JENKINSURL=$2
        shift;shift ;;
    -japicred | --jenkins_api_cred )
        JENKINSAPICREDENTIALS=$2
        shift;shift ;;
    -jgitcred | --jenkins_git_credentials_id )
        JENKINSGITCREDENTIALS=$2
        shift;shift ;;        
    -- ) shift ;;
    * )  break ;;
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
  echo -e "\tBuilding repository for $ARTIFACTID for $BITBUCKETUSER?"
  pushd built_project
    pushd $ARTIFACTID
      bitbucketcred=
      if [ "$BITBUCKETUSER" != "" ]
      then
        echo -e "\tI have an user..."
        if [ "$BITBUCKETPASS" != "" ]
        then
          echo -e "\tI have a pass..."
          bitbucketcred=$BITBUCKETUSER:$BITBUCKETPASS
        else
          bitbucketcred=$BITBUCKETUSER
        fi
        if [ "$BITBUCKETTEAM" != "" ] && [ "$BITBUCKETPROJECTKEY" != "" ];
        then
          echo -e "\tI have team and project key, lets go... $BITBUCKETURL/$BITBUCKETTEAM/$ARTIFACTID"
          command="curl -X POST  -u $bitbucketcred $BITBUCKETURL/$BITBUCKETTEAM/$ARTIFACTID -H \"Content-Type: application/json\"  -d '{\"has_wiki\": true, \"is_private\": true, \"project\": {\"key\": \"$BITBUCKETPROJECTKEY\"}}'"
          result=$(eval "$command")
          echo "$result"
          remote_url=$(echo $result | jq -r ".links.clone[0].href")
          echo '   Pushing to repository '$remote_url

          if [ "" = "$remote_url" ]
          then 
              echoerr "Error creating repo $result";
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
            if [[ $rc -eq 0 ]] ; then GIT_REPO_URL=$remote_url; fi
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

# String to replace, replacement string
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

#  String to replace, replacement string, origin , destination
function replaceInFile
{
  echo "Replacing names $1 $2"
  patternReplace=$(echo "$1" | sed 's/\./\\\./g')
  patternCollection=$(echo "$2" | sed 's/\./\\\./g')
  patternCollection=$(echo $patternCollection | sed 's/\//\\\//g')
  file=$3;

  case "$(uname -s)" in

      Darwin)
        echo '  MacoS replace'
        echo "Modifying $file....."; sed -i '' "s/$patternReplace/$patternCollection/g" $file;
        ;;
      *)
        echo '  Linuz replaces'
        echo "Modifying $file....."; sed -i  "s/$patternReplace/$patternCollection/g" $file;
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
    echo "Applying registry [$1] in [$2] ..."
    patternCollection=$1
    patternCollection=$(echo $patternCollection | sed 's/\//\\\//g')

    case "$(uname -s)" in

       Darwin)
         echo '   MacoS replace'
         fgrep -Rl "=#REGISTRY_DOMAIN_NAME#" . | while read file; do echo "Modifying $file....."; sed -i '' "s/=$2/=$patternCollection/g" $file; done
         ;;
       *)
         echo '   Linuz replaces'
         fgrep -Rl "=#REGISTRY_DOMAIN_NAME#" . | while read file; do echo "Modifying $file....."; sed -i  "s/=$2/=$patternCollection/g" $file; done
         ;;
    esac
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
        -DarchetypeGroupId=com.meph \
        -DarchetypeArtifactId=mephskeleton-archetype \
        -DarchetypeVersion=DEVELOP-SNAPSHOT \
        -DgroupId=$GROUPID -DartifactId=$ARTIFACTID -Dversion=DEVELOP-SNAPSHOT\
        -DarchetypeRepository=../mephskeleton/target/generated-sources/archetype/ \
        -DinteractiveMode=false
    echo "Now, what archetype does not do :\) ..."
    echo "Copying pipeline ..."
    cp -R ../mephskeleton/build_pipeline/* $ARTIFACTID/build_pipeline/
    #mkdir -p $ARTIFACTID/jenkinsfile_parts
    #cp -R ../mephskeleton/jenkinsfile_parts/* $ARTIFACTID/jenkinsfile_parts
    echo "Adding .gitignore \( guessing you're using git, if not, you can clean it..."    
    cp ../mephskeleton/.gitignore $ARTIFACTID/
    echo "Copying Jenkinsfile"
    cp ../mephskeleton/Jenkinsfile $ARTIFACTID/  
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

    echo "Applying gesistry [$DOCKERREGISTRYDOMAINAME] ..."
    if [ "$DOCKERREGISTRYDOMAINAME" == "" ]; then
      echo "WARN : Docker repository not defined, you'll have to edit build_pipeline/00_env_pipeline.sh to set it!!!"
    else
      replaceDomain $DOCKERREGISTRYURL "#REGISTRY_URL#"
      replaceDomain $DOCKERREGISTRYDOMAINAME "#REGISTRY_DOMAIN_NAME#"
    fi

    #echo "Setting jenkins credentials to [$JENKINS_CREDENTIALS]"
    #reemplazaJenkinsCredentials $JENKINS_CREDENTIALS

    echo "Adding permissions for shell scripts..."
    find . -name "*.sh" | while read file; do chmod 744 $file; done
    chmod 744 ./$ARTIFACTID/build_pipeline/*.sh
    #chmod 744 ./$ARTIFACTID/jenkins_tasks/*.sh
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

function buildJenkinsTaskIfNeeded
{
  pushd jenkins
  echo "Checking jenkins task creation..."
  if [ "$JENKINSURL" != "" ]; then
    echo "Checking jenkins task creation... got Url"
    if [ "$JENKINSAPICREDENTIALS" != "" ]; then
      echo "Checking jenkins task creation... got credentials"
      if [ "$JENKINSGITCREDENTIALS" != "" ]; then
        echo "Checking jenkins task creation... got git credentials"
        echo "Git repo : $GIT_REPO_URL"
        if [ "$GIT_REPO_URL" != "" ]; then
          echo "Jenkins, checking folder $BITBUCKETPROJECTKEY"
          existsFolder=$(curl -s -X GET $JENKINSURL'/job/'$BITBUCKETPROJECTKEY'/config.xml' -u $JENKINSAPICREDENTIALS -i | grep "HTTP/" | grep -v 100 | cut -d" " -f2)
          if [ "$existsFolder" = "404" ]; then
            existsFolder=$(curl -s -XPOST $JENKINSURL'/createItem?name='$BITBUCKETPROJECTKEY -u $JENKINSAPICREDENTIALS --data-binary @jenkins_folder_template.xml -H "Content-Type:text/xml" -i | grep "HTTP/" | grep -v 100 | cut -d" " -f2)
            echo 'Folder creation result: with '$JENKINSURL'/createItem?name='$BITBUCKETPROJECTKEY' : '$existsFolder
          else
            echo "Jenkins, no need to create folder"
          fi;
          
          folder="/job/$BITBUCKETPROJECTKEY/";

          if [[ "$existsFolder" == "200" ]];
          then
              echo "Creating jenkins task ...$ARTIFACTID with $GIT_REPO_URL";              
              rm ./jenkins_template_tmp.xml;
              cp ./jenkins_template.xml ./jenkins_template_tmp.xml
              replaceInFile "GIT_REPOSITORY" "$GIT_REPO_URL" ./jenkins_template_tmp.xml;
              replaceInFile "GIT_CREDENTIALS_ID" "$JENKINSGITCREDENTIALS" ./jenkins_template_tmp.xml;
              existsTask=$(curl -s -XPOST $JENKINSURL$folder'createItem?name='$ARTIFACTID -u $JENKINSAPICREDENTIALS --data-binary @jenkins_template_tmp.xml -H "Content-Type:text/xml" -i | grep "HTTP/" | grep -v 100 | cut -d" " -f2)
          else 
            echo 'Could not find folder in jenkins '$BITBUCKETPROJECTKEY
          fi;

          if [ "$existsTask" == "200" ]; then 
              echo "Jenkins task created $BITBUCKETPROJECTKEY/$ARTIFACTID"
          else 
            echo 'Could not create task '$BITBUCKETPROJECTKEY' with '"$JENKINSURL$folder"'createItem?name='$ARTIFACTID' result :'$existsTask
          fi
        else
          echo "We don't create jenkins task due to we don't have a git repo."
        fi
      fi
    fi
  fi;
  popd
}

echo "Preparing service for artifact $1"

buildprojectFromArchetype
replaceNamesInBuiltProject
createBitbucketProjectIfNeeded
buildJenkinsTaskIfNeeded
