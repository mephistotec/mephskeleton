#!/usr/bin/env bash

# Ecritura en canal de error
echoerr() { (>&2 echo "$@"); }

function loginRegistry
{
    # Login to k8s AWS account
    registry_command=get_registry_command;
    $($registry_command)

    rc=$?
    echo "------------ Login to registry end $rc -----------"
    if [[ $rc -ne 0 ]] ; then
      echo '--- ERROR APLICANDO ENTORNO $env_filename '; exit $rc
    fi
}

function assumeK8Srole
{
    echo "assuming role k8s"
    temp_role=$(aws sts assume-role --role-arn "arn:aws:iam::495248209902:role/KRAVD-Api-Access" --role-session-name "cicd-sysops")

    echo "apply environment for role k8s $temp_role"

    export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq .Credentials.AccessKeyId | xargs)
    export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq .Credentials.SecretAccessKey | xargs)
    export AWS_SESSION_TOKEN=$(echo $temp_role | jq .Credentials.SessionToken | xargs)
}

function aplicaEntorno
{
    env_filename="./environment_scripts/env_$1.sh";
    if [ ! -f  $env_filename ];
    then
        echoerr "ERROR : No existe $env_filename";
        exit -1;
    fi
    echoerr "====> inicializando env [$1] --> $env_filename";
    eval ". $env_filename";
    rc=$?
    if [[ $rc -ne 0 ]] ; then
      echo '--- ERROR APLICANDO ENTORNO $env_filename '; exit $rc
    fi
}

function pintaQueScriptSoy
{
    echo "-------------------------------------------------------------"
    echo "-------------------------------------------------------------"
    echo "-------------------------------------------------------------"
    echo "---------------- $(basename -- \"$0\") ----------------------"
    echo "-------------------------------------------------------------"
    echo "-------------------------------------------------------------"
    echo "-------------------------------------------------------------"

}

function commitStackVersionFile
{
    echo commitStackVersionFile $1
    branch=$(git branch | grep \* | cut -d ' ' -f2-  )
    if [[ "$BRANCH" == "" ]]; then
        BRANCH=$branch
    fi
    remote_branch=$(echo $BRANCH | sed "s/origin\///g")
    branch
    echo "------ Push Command --------"
    echo "---- STATUS ------"
    git status
    echo "---- Current branches ------"
    git branch
    echo "-------- add $1 -------------"
    git add $1
    echo "---------commit ---------------"
    git commit -m "SB-427 versionfile $2"
    git remote set-url origin https://${CICD_USER}:${CICD_PASS}@jira.mangodev.net/stash/scm/sb/mephmicro.git
    command="git push origin $branch:$remote_branch"
    echo $command
    eval $command

}
