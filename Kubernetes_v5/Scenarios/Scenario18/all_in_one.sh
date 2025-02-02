#!/bin/bash

# OPTIONAL PARAMETERS: 
# PARAMETER1: Docker hub login
# PARAMETER2: Docker hub password

if [[ $# -ne 2 ]]; then
  TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
  RATEREMAINING=$(curl --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest 2>&1 | grep -i ratelimit-remaining | cut -d ':' -f 2 | cut -d ';' -f 1 | cut -b 1- | tr -d ' ')

  if [[ $RATEREMAINING -lt 20 ]]; then
      echo "---------------------------------------------------------------------------------------------------------------------------"
      echo "- Your anonymous login to the Docker Hub does not have many pull requests left ($RATEREMAINING). Consider using your own credentials"
      echo "---------------------------------------------------------------------------------------------------------------------------"
      echo
      echo "Please restart the script with the following parameters:"
      echo " - Parameter1: Docker hub login"
      echo " - Parameter2: Docker hub password"
      exit 0
  fi
fi

echo "#######################################################################################################"
echo " 1. Install MetalLB on Kubernetes"
echo " 2. Install Gitea on RHEL4"
echo " 3. Install ArgoCD on Kubernetes"
echo " 4. Push Scenario Docker Images to private repo"
echo " 5. Uninstall Trident"
echo " 6. Configuration local Git variables"
echo " 7. Create a Git repository"
echo " 8. Push data to the repository"
echo " 9. Update .bashrc (if not already done)"
echo "#######################################################################################################"

if [[ $(yum info jq -y 2> /dev/null | grep Repo | awk '{ print $3 }') != "installed" ]]; then
    echo "#######################################################################################################"
    echo "Install JQ"
    echo "#######################################################################################################"
    yum install -y jq
fi

# Install MetalLB, Gitea & ArgoCD
if [[ $# -eq 2 ]]; then
  sh ../../Addendum/Addenda05/all_in_one.sh $1 $2
  sh ../../Addendum/Addenda11/all_in_one.sh $1 $2
  sh ../../Addendum/Addenda12/all_in_one.sh $1 $2
else
  sh ../../Addendum/Addenda05/all_in_one.sh
  sh ../../Addendum/Addenda11/all_in_one.sh
  sh ../../Addendum/Addenda12/all_in_one.sh
fi

cd ~/LabNetApp/Kubernetes_v5/Scenarios/Scenario18
if [[ $# -eq 2 ]]; then
  sh push_scenario_images_to_private_repo.sh $1 $2
else
  sh push_scenario_images_to_private_repo.sh
fi
sh trident_uninstall.sh

git config --global user.email lod.demo.netapp.com
git config --global user.name "lod"
git config --global credential.helper store
git config --global alias.adcom '!git add -A && git commit -m'
git config --global push.default simple

echo
echo "#######################################################################################################"
echo " Connect to Gitea: http://192.168.0.64:3000/"
echo " Create the administrator account: demo/netapp123/demo@demo.netapp.com"
echo "#######################################################################################################"
echo

read -rsp $'Press any key to continue once Gitea configuration is done...\n' -n1 key

curl -X POST "http://192.168.0.64:3000/api/v1/user/repos" -u demo:netapp123 -H "accept: application/json" -H "content-type: application/json" -d '{
  "name":"scenario18",
  "description": "argocd repo"
}'

echo
echo "###### Push Data to the Repository"
echo "# You are going to be asked to enter the Gitea login & pwd: demo/netapp123"
echo "######"
echo
cp -R ~/LabNetApp/Kubernetes_v5/Scenarios/Scenario18/Repository ~/
cd ~/Repository
git init
git add .
git commit -m "initial commit"
git remote add origin http://192.168.0.64:3000/demo/scenario18.git
git push -u origin master

echo
echo "#######################################################################################################"
ARGOCDIP=$(kubectl get svc -n argocd argocd-server --no-headers | awk '{ print $4 }')
ARGOCDPWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo " TO CONNECT TO ArgoCD, USE THE FOLLOWING ADDRESS: $ARGOCDIP"
echo " TO LOG INTO ArgoCD WITH 'admin', USE THE FOLLOWING PASSWORD: $ARGOCDPWD"
echo "#######################################################################################################"
echo

if [[  $(more ~/.bashrc | grep kedit | wc -l) -eq 0 ]];then
  echo
  echo "#######################################################################################################"
  echo "#"
  echo "# UPDATE BASHRC"
  echo "#"
  echo "#######################################################################################################"
  echo

  cp ~/.bashrc ~/.bashrc.bak
  cat <<EOT >> ~/.bashrc
source <(kubectl completion bash)
complete -F __start_kubectl k

alias kc='kubectl create'
alias kg='kubectl get'
alias kdel='kubectl delete'
alias kdesc='kubectl describe'
alias kedit='kubectl edit'
alias trident='tridentctl -n trident'
EOT

  bash
fi