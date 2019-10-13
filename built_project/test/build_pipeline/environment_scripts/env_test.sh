#!/usr/bin/env bash

export K8S_ELB=internal-alb-eks-internal-dev-1937715155.eu-west-1.elb.amazonaws.com
export K8S_EKS_ENV=mango.dev
export K8S_DESCRIPTORS_ENV=dev

export MODEL_DATASOURCE_USER=APPWIZ
export MODEL_DATASOURCE_URL="jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=bd.int.dev.mango.com)(PORT=1521))(CONNECT_DATA=(service_name=MNGPRES)))"

export MODEL_DATASOURCE_PASSWORD_SECRET=test_bbdd_PASSWORD_SECRET

export S3_LSDOMAINS_PATH=test-mng-releases/code

##---------------------------------------------------------
## Estos campos sirven para la validacion de la version
## no son entorno
##---------------------------------------------------------
echo "Seteamos URLS"
> tmp/urls_health.txt
> tmp/urls_version.txt
if [ -d "../test-restapiApp" ]; then
    echo "http://${DOCKER_RESTAPI_DOMAIN_NAME}.dev.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_RESTAPI_DOMAIN_NAME}.dev.k8s.mango/info" >> tmp/urls_version.txt
fi;
if [ -d "../test-engineApp" ]; then
    echo "http://${DOCKER_ENGINE_DOMAIN_NAME}.dev.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_ENGINE_DOMAIN_NAME}.dev.k8s.mango/info" >> tmp/urls_version.txt
fi
