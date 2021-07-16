#!/bin/bash


echo "Creating the volume..."

kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/persistent-volume.yml
kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/persistent-volume-claim.yml


echo "Creating the database credentials..."

kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/mysql-secret.yaml

echo "Creating the database configmap credentials..."

kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/database-configmap.yaml


echo "Creating the mysql deployment and service..."

kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/mysql-deployment-service.yml

echo "Creating the service configmap credentials..."

kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/servers-configmap.yaml


echo "Creating the update deployment and service..."

kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/update-deployment.yaml
kubectl apply -f /home/ubuntu/jenkins-k8s/kubernetes/update-service.yml


echo "Creating the result deployment and service..."

kubectl apply -f /home/ubuntu/jenkins-k8s/result/result-deployment.yml
kubectl apply -f /home/ubuntu/jenkins-k8s/result/result-service.yml

