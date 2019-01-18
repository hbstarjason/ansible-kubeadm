#!/bin/bash
# Get the dashboard token for admin user
echo  "\033[41;36m Login to kubernetes dashboard at https://192.16.35.12:30000 with the following token \033[0m"
kubectl -n kube-system describe secret `kubectl -n kube-system get secret|grep admin-token|cut -d " " -f1`|grep "token:"|tr -s " "|cut -d " " -f2