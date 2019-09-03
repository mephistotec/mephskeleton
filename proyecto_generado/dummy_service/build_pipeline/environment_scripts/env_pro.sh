#!/usr/bin/env bash

export K8S_ELB=internal-alb-eks-internal-pro-1001902958.eu-west-1.elb.amazonaws.com
export K8S_EKS_ENV=mango.pro
export K8S_DESCRIPTORS_ENV=pro

export MODEL_DATASOURCE_USER=APPWIZ
export MODEL_DATASOURCE_URL="jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=bd.int.pro.mango.com)(PORT=1521))(CONNECT_DATA=(service_name=MANGO)))"

export MODEL_DATASOURCE_PASSWORD_SECRET=dummy_service_bbdd_PASSWORD_SECRET

export S3_LSDOMAINS_PATH=mng-releases/code

##---------------------------------------------------------
## Estos campos sirven para la validacion de la version
## no son entorno
##---------------------------------------------------------
echo "Seteamos URLS"
#Cogemos los composes relevantes
> tmp/urls_health.txt
> tmp/urls_version.txt
if [ -d "../dummy_service-restapiApp" ]; then
    echo "http://${DOCKER_RESTAPI_DOMAIN_NAME}.pro.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_RESTAPI_DOMAIN_NAME}.pro.k8s.mango/info" >> tmp/urls_version.txt
fi;
if [ -d "../dummy_service-engineApp" ]; then
    echo "http://${DOCKER_ENGINE_DOMAIN_NAME}.pro.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_ENGINE_DOMAIN_NAME}.pro.k8s.mango/info" >> tmp/urls_version.txt
fi
if [ -d "../dummy_service-singleApp" ]; then
    echo "http://${DOCKER_SINGLEAPP_DOMAIN_NAME}.pro.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_SINGLEAPP_DOMAIN_NAME}.pro.k8s.mango/info" >> tmp/urls_version.txt
fi
