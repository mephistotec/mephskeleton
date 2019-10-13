#!/usr/bin/env bash
echo "-------------- entorno previo a kravd ---------------"
env | grep AWS
echo "-------------- levantamos imagen kravd ---------------"
#docker build . --tag kravd_docker
docker run -t -v $HOME/.aws:/root/.aws \
    -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    -v $3:/descriptors \
    --rm kravd_docker /kravd_shell.sh /descriptors/$1 $2