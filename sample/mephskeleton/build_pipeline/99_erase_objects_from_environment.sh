#!/usr/bin/env bash

. ./00_env_pipeline.sh

entorno=$ENTORNO_PIPELINE
if [ "$entorno" == "" ];
then
    echo "ERROR falta entorno  (-e <env>)"
    exit -1
fi

eks-loadenv $K8S_EKS_ENV

kubectl delete deployment mephskeleton-restapi-deployment -n mango
kubectl delete ConfigMap configmap-mephskeleton-restapi -n mango
kubectl delete HorizontalPodAutoscaler mephskeleton-restapi-hpa -n mango
kubectl delete NetworkPolicy mephskeleton-restapi -n mango
kubectl delete Service mephskeleton-restapi -n mango
kubectl delete Ingress mephskeleton-restapi -n mango
kubectl delete PodDisruptionBudget mephskeleton-restapi-pdb -n mango

kubectl delete deployment mephskeleton-engine-deployment -n mango
kubectl delete ConfigMap configmap-mephskeleton-engine -n mango
kubectl delete HorizontalPodAutoscaler mephskeleton-engine-hpa -n mango
kubectl delete NetworkPolicy mephskeleton-engine -n mango
kubectl delete Service mephskeleton-engine -n mango
kubectl delete Ingress mephskeleton-engine -n mango
kubectl delete PodDisruptionBudget mephskeleton-engine-pdb -n mango
