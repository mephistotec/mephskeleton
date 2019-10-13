#!/usr/bin/env bash

. ./00_env_pipeline.sh

entorno=$ENTORNO_PIPELINE
if [ "$entorno" == "" ];
then
    echo "ERROR falta entorno  (-e <env>)"
    exit -1
fi

eks-loadenv $K8S_EKS_ENV

kubectl delete deployment test-restapi-deployment -n mango
kubectl delete ConfigMap configmap-test-restapi -n mango
kubectl delete HorizontalPodAutoscaler test-restapi-hpa -n mango
kubectl delete NetworkPolicy test-restapi -n mango
kubectl delete Service test-restapi -n mango
kubectl delete Ingress test-restapi -n mango
kubectl delete PodDisruptionBudget test-restapi-pdb -n mango

kubectl delete deployment test-engine-deployment -n mango
kubectl delete ConfigMap configmap-test-engine -n mango
kubectl delete HorizontalPodAutoscaler test-engine-hpa -n mango
kubectl delete NetworkPolicy test-engine -n mango
kubectl delete Service test-engine -n mango
kubectl delete Ingress test-engine -n mango
kubectl delete PodDisruptionBudget test-engine-pdb -n mango
