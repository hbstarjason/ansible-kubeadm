#!/bin/bash
# repair dashboard login

cd ~/  && mkdir certs
openssl req -nodes -newkey rsa:2048 -keyout certs/dashboard.key -out certs/dashboard.csr -subj "/C=/ST=/L=/O=/OU=/CN=kubernetes-dashboard"
openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
kubectl delete secret kubernetes-dashboard-certs -n kube-system
kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
kubectl delete pods $(kubectl get pods -n kube-system|grep kubernetes-dashboard|awk '{print $1}') -n kube-system 