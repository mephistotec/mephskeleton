#!/usr/bin/env bash

. ./00_env_pipeline.sh

entorno=$ENTORNO_PIPELINE
if [ "$entorno" == "" ];
then
    echo "ERROR falta entorno  (-e <env>)"
    exit -1
fi

eks-loadenv $K8S_EKS_ENV

kubectl delete deployment dummy_service-restapi-deployment -n mango
kubectl delete ConfigMap configmap-dummy_service-restapi -n mango
kubectl delete HorizontalPodAutoscaler dummy_service-restapi-hpa -n mango
kubectl delete NetworkPolicy dummy_service-restapi -n mango
kubectl delete Service dummy_service-restapi -n mango
kubectl delete Ingress dummy_service-restapi -n mango
kubectl delete PodDisruptionBudget dummy_service-restapi-pdb -n mango

kubectl delete deployment dummy_service-engine-deployment -n mango
kubectl delete ConfigMap configmap-dummy_service-engine -n mango
kubectl delete HorizontalPodAutoscaler dummy_service-engine-hpa -n mango
kubectl delete NetworkPolicy dummy_service-engine -n mango
kubectl delete Service dummy_service-engine -n mango
kubectl delete Ingress dummy_service-engine -n mango
kubectl delete PodDisruptionBudget dummy_service-engine-pdb -n mango
