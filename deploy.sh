#!/bin/bash


echo "Creating the volume..."

kubectl apply -f ./kubernetes/persistent-volume.yml
kubectl apply -f ./kubernetes/persistent-volume-claim.yml


echo "Creating the database credentials..."

kubectl apply -f ./kubernetes/mysql-secret.yaml

echo "Creating the database configmap credentials..."

kubectl apply -f ./kubernetes/database-configmap.yaml


echo "Creating the mysql deployment and service..."

kubectl apply -f ./kubernetes/mysql-deployment-service.yml

echo "Creating the service configmap credentials..."

kubectl apply -f ./kubernetes/servers-configmap.yaml


echo "Creating the update deployment and service..."

kubectl apply -f ./kubernetes/update-deployment.yaml
kubectl apply -f ./kubernetes/update-service.yml


echo "Creating the result deployment and service..."

kubectl apply -f ./result/result-deployment.yml
kubectl apply -f ./result/result-service.yml
