#!/usr/bin/env bash

export K8S_ELB=internal-alb-eks-internal-pre-2139479291.eu-west-1.elb.amazonaws.com
export K8S_EKS_ENV=mango.pre
export K8S_DESCRIPTORS_ENV=pre

export MODEL_DATASOURCE_USER=APPWIZ
export MODEL_DATASOURCE_URL="jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=bd.int.pre.mango.com)(PORT=1521))(CONNECT_DATA=(service_name=MNGPRED)))"

export MODEL_DATASOURCE_PASSWORD_SECRET=mephmicro_bbdd_PASSWORD_SECRET

export S3_LSDOMAINS_PATH=pre-mng-releases/code

##---------------------------------------------------------
## Estos campos sirven para la validacion de la version
## no son entorno
##---------------------------------------------------------
echo "Seteamos URLS"
#Cogemos los composes relevantes
> tmp/urls_health.txt
> tmp/urls_version.txt
if [ -d "../mephmicro-restapiApp" ]; then
    echo "http://${DOCKER_RESTAPI_DOMAIN_NAME}.pre.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_RESTAPI_DOMAIN_NAME}.pre.k8s.mango/info" >> tmp/urls_version.txt
fi;
if [ -d "../mephmicro-engineApp" ]; then
    echo "http://${DOCKER_ENGINE_DOMAIN_NAME}.pre.k8s.mango/health" >> tmp/urls_health.txt
    echo "http://${DOCKER_ENGINE_DOMAIN_NAME}.pre.k8s.mango/info" >> tmp/urls_version.txt
fi
