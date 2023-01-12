# gloo-ops
Manage Gloo Platform the GitOps way

## Prerequisites

prerequisites: 
- argocd cli
- terraform cli


## Gloo on EKS

1. Run terraform apply
2. run 
```bash
make generate-kubeconfig
```
4. Run the following
```bash
export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2
export license="your license key"
```

1. Install argo and registere k8s cluster
```bash
make install-argo-full
```

Get the argo cd external loadbalancer ingress address from the mgmt cluster:
```bash
export ARGO_URL=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].*}' --context ${MGMT})
```

Login to argo using username admin and password amin:
```bash
argocd login ${ARGO_URL} --username admin --password admin --insecure
```


This will install argo onto your cluster.
Create a branch or fork the following github repo:

https://github.com/solo-io/gloo-ops

We will use this as a base in the following steps. 

Now we need to register the workload clusters to argo. For this exercise we will use the argocd command, however in production you may want to create the account and kubeconfig file manually. 


```bash
argocd cluster add ${MGMT} -y --in-cluster --name ${MGMT}
argocd cluster add ${CLUSTER1} -y --name ${CLUSTER1}
argocd cluster add ${CLUSTER2} -y --name ${CLUSTER2}
```

2. Install gloo mesh

First create the gloo-mesh project on the management cluster.
We will first make sure to use right license key
```bash
sed -i "s/your license key/${license}/g" gloo-mesh/gloo-mesh-enterprise.yaml
k apply -n argocd -f argo/appproject-gloo-mgm.yaml --context ${MGMT}
```

Now if you want to have Argo use helm for the install run the following to add the helm deployment to argo:
```bash
k apply -n argocd -f argo/gloo/mgmt-server/helm/app-mgmt-server.yaml --context ${MGMT}
```


1. Run the following to generate the secrets to connect the cluster to the gloo mgmt plane:
```bash
kubectl --context ${CLUSTER1} create ns gloo-mesh
kubectl get secret relay-root-tls-secret -n gloo-mesh --context ${MGMT} -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context ${CLUSTER1} --from-file ca.crt=ca.crt
rm ca.crt

kubectl get secret relay-identity-token-secret -n gloo-mesh --context ${MGMT} -o jsonpath='{.data.token}' | base64 -d > token
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context ${CLUSTER1} --from-file token=token
rm token


kubectl --context ${CLUSTER2} create ns gloo-mesh
kubectl get secret relay-root-tls-secret -n gloo-mesh --context ${MGMT} -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context ${CLUSTER2} --from-file ca.crt=ca.crt
rm ca.crt

kubectl get secret relay-identity-token-secret -n gloo-mesh --context ${MGMT} -o jsonpath='{.data.token}' | base64 -d > token
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context ${CLUSTER2} --from-file token=token
rm token
```
7. Run the folling
```bash
export ENDPOINT_GLOO_MESH=$(kubectl --context ${MGMT} -n gloo-mesh get svc gloo-mesh-mgmt-server -o jsonpath='{.status.loadBalancer.ingress[0].*}'):9900
export HOST_GLOO_MESH=$(echo ${ENDPOINT_GLOO_MESH} | cut -d: -f1)
echo "---"
echo $ENDPOINT_GLOO_MESH
```
8. Register clusters to gloo - You need to run this on the management cluster.  We do this by deploying an argo app that will manage the gloo client clusters
   
First Change the address of the mesh server in gloo client cluster 1 and 2
```bash  
sed -i '' "s/localhost:9900/${ENDPOINT_GLOO_MESH}/g" argo/gloo/agent-config/helm/gloo-client-cluster1.yaml
sed -i '' "s/localhost:9900/${ENDPOINT_GLOO_MESH}/g" argo/gloo/agent-config/helm/gloo-client-cluster2.yaml
git commit --all -m "change gloo mesh server endpoint"
git push origin main
```
   
```bash
k apply --context ${MGMT} -f "argo/gloo/agent-config/agentconfig-app.yaml"
```

9.  
```bash
kubectl --context ${MGMT} apply -f "argo/gloo/gateways/cross-cluster-gateway.yaml"
```
10.
```bash
kubectl --context ${CLUSTER1} create ns istio-gateways
kubectl --context ${CLUSTER1} apply -f "argo/gloo/gateways/cluster1"
kubectl --context ${CLUSTER2} create ns istio-gateways
kubectl --context ${CLUSTER2} apply -f "argo/gloo/gateways/cluster2"
```
12.
```bash
kubectl --context ${MGMT} apply -f "argo/gloo/istio-lifecycle"
```
