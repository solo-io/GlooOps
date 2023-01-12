.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: push stop start install-argo install-argo-full	

bold := $(shell tput bold)
normal := $(shell tput sgr0)
# VM := $(shell terraform output -raw vm_instanceid)
# MINIKUBE := $(shell terraform output -raw minikube_instanceid)
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

push:
	git add . 
	git commit -a -m "${MESSAGE}" 
	git push origin
stop-eks:
	aws eks update-nodegroup-config --cluster-name gloo-ops-cluster1  --nodegroup-name cluster1-ng --scaling-config  minSize=0,desiredSize=0 --region eu-west-3 --no-cli-pager
	aws eks update-nodegroup-config --cluster-name gloo-ops-cluster2  --nodegroup-name cluster2-ng --scaling-config  minSize=0,desiredSize=0 --region eu-west-3 --no-cli-pager
	aws eks update-nodegroup-config --cluster-name gloo-ops-mgmt --nodegroup-name mgmt-ng1 --scaling-config  minSize=0,desiredSize=0 --region eu-west-3 --no-cli-pager
start-eks:
	
	aws eks update-nodegroup-config --cluster-name gloo-ops-cluster1  --nodegroup-name cluster1-ng --scaling-config  minSize=1,desiredSize=1 --region eu-west-3 --no-cli-pager
	aws eks update-nodegroup-config --cluster-name gloo-ops-cluster2  --nodegroup-name cluster2-ng --scaling-config  minSize=1,desiredSize=1 --region eu-west-3 --no-cli-pager
	aws eks update-nodegroup-config --cluster-name gloo-ops-mgmt --nodegroup-name mgmt-ng1 --scaling-config  minSize=1,desiredSize=1 --region eu-west-3 --no-cli-pager
install-argo:
	kubectl create namespace argocd --context mgmt
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.17/manifests/install.yaml --context mgmt
	kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}' --context mgmt
install-argo-rollouts: install-argo
	kubectl create namespace argo-rollouts --context mgmt
	kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml --context mgmt
install-argo-full: install-argo-rollouts
	kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"admin.password": "$2a$10$ldvEUwliowstaKXsWbK5b.mvN79pN8yFqQzq1Vq50fIEnzHGhljCa","admin.passwordMtime": "'$(date +%FT%T%Z)'"}}' --context mgmt
generate-kubeconfig:
	aws eks update-kubeconfig --region eu-west-3 --name gloo-ops-cluster2 --alias cluster2  
	aws eks update-kubeconfig --region eu-west-3 --name gloo-ops-cluster1 --alias cluster1  
	aws eks update-kubeconfig --region eu-west-3 --name gloo-ops-mgmt --alias mgmt 
	kubectl config use-context mgmt 
add-argo-cluster:
	argocd cluster add  cluster1 
validate-tf:
	terraform init -upgrade
	terraform validate
	
	