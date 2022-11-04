#!/bin/bash

# PARAMETER 1: Hostname or IP
# PARAMETER 2: Docker Hub Login
# PARAMETER 3: Docker Hub Password

echo "#############################"
echo "# DOCKER LOGIN ON HOST $1"
echo "#############################"
ssh -o "StrictHostKeyChecking no" root@$1 docker login -u $2 -p $3

echo "################################"
echo "# PULLING IMAGES FROM DOCKER HUB"
echo "################################"

echo "####################################"
echo "# netapp/trident:22.10.0"
echo "####################################"
ssh -o "StrictHostKeyChecking no" root@$1 docker pull netapp/trident:22.10.0

echo "####################################"
echo "# netapp/trident-operator:22.10.0"
echo "####################################"
ssh -o "StrictHostKeyChecking no" root@$1 docker pull netapp/trident-operator:22.10.0

echo "####################################"
echo "# netapp/trident-autosupport:22.10.0"
echo "####################################"
ssh -o "StrictHostKeyChecking no" root@$1 docker pull netapp/trident-autosupport:22.10.0

echo "#############################################"
echo "# Dealing with the Prometheus operator images"
echo "#############################################"
ssh -o "StrictHostKeyChecking no" root@$1 docker pull busybox:1.31.1
ssh -o "StrictHostKeyChecking no" root@$1 docker pull jettech/kube-webhook-certgen:v1.5.0
ssh -o "StrictHostKeyChecking no" root@$1 docker pull grafana/grafana:7.5.5

GRAFANAHOST=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o=jsonpath='{.items[0].spec.nodeName}')
if [[ $1 != $GRAFANAHOST ]];then
  ssh -o "StrictHostKeyChecking no" root@$1 docker pull grafana/grafana:7.0.3
  ssh -o "StrictHostKeyChecking no" root@$1 docker pull kiwigrid/k8s-sidecar:0.1.151
fi

PROMETHEUSHOST=$(kubectl get -n monitoring pod -l app=prometheus-operator-operator -o=jsonpath='{.items[0].spec.nodeName}')
if [[ $1 != $PROMETHEUSHOST ]];then
  ssh -o "StrictHostKeyChecking no" root@$1 docker pull squareup/ghostunnel:v1.5.2
fi

if [[ ! "$1" =~ ^(rhel1|rhel2|rhel3)$ ]];then
  echo "############################################################"
  echo "# Dealing with the Calico images when using a larger cluster"
  echo "############################################################"
  ssh -o "StrictHostKeyChecking no" root@$1 docker pull calico/cni:v3.15.1
  ssh -o "StrictHostKeyChecking no" root@$1 docker pull calico/node:v3.15.1
  ssh -o "StrictHostKeyChecking no" root@$1 docker pull calico/pod2daemon-flexvol:v3.15.1
fi