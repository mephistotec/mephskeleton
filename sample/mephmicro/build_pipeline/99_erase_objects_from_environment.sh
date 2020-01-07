#!/usr/bin/env bash

. ./00_env_pipeline.sh

entorno=$ENTORNO_PIPELINE
if [ "$entorno" == "" ];
then
    echo "ERROR falta entorno  (-e <env>)"
    exit -1
fi

eks-loadenv $K8S_EKS_ENV

kubectl delete deployment mephmicro-restapi-deployment -n mango
kubectl delete ConfigMap configmap-mephmicro-restapi -n mango
kubectl delete HorizontalPodAutoscaler mephmicro-restapi-hpa -n mango
kubectl delete NetworkPolicy mephmicro-restapi -n mango
kubectl delete Service mephmicro-restapi -n mango
kubectl delete Ingress mephmicro-restapi -n mango
kubectl delete PodDisruptionBudget mephmicro-restapi-pdb -n mango

kubectl delete deployment mephmicro-engine-deployment -n mango
kubectl delete ConfigMap configmap-mephmicro-engine -n mango
kubectl delete HorizontalPodAutoscaler mephmicro-engine-hpa -n mango
kubectl delete NetworkPolicy mephmicro-engine -n mango
kubectl delete Service mephmicro-engine -n mango
kubectl delete Ingress mephmicro-engine -n mango
kubectl delete PodDisruptionBudget mephmicro-engine-pdb -n mango
