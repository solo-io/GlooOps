# 1. gloo-ops
Manage Gloo Platform the GitOps way



## 1.1. Prerequisites

prerequisites: 
- argocd cli
- terraform cli

## 1.2. Gloo on EKS

To creat the eks cluster with terraform run
```bash
terraform apply /terraform
```

Let's get the kubeconfig for the cluster

```bash
make generate-kubeconfig
```

Store the following environment veriable to store the context names:

```bash
export MGMT=mgmt
export CLUSTER1=cluster1
export CLUSTER2=cluster2
export license="your license key"
```

## 1.3. Install Gloo

### Install Argo and register the k8s clusters into argo

```bash
make install-argo-full
```
This will install argo, argo-rollouts and

Get the argo cd external loadbalancer ingress address from the mgmt cluster:

```bash
export ARGO_URL=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].*}' --context ${MGMT})
```

Login to argo using username admin and password amin:

```bash
argocd login ${ARGO_URL} --username admin --password admin --insecure
```

Register the clusters to argo:

```bash
argocd cluster add ${MGMT} -y --in-cluster --name ${MGMT} #This will change the name from in-cluster to mgmt. Which we will need later
argocd cluster add ${CLUSTER1} -y --name ${CLUSTER1}
argocd cluster add ${CLUSTER2} -y --name ${CLUSTER2}
```
note: if you get an error that the cluster is already registered, you can delete the cluster from argo and re-register it.
It is important to note that the kubeapi server that is used in the kubeconfig is also accessible by the argocd server. If you are using a private cluster, you will need to make sure that the argocd server can access the kubeapi server.


### Clone/branch/fork the GlooOps github repo
This will install argo onto your cluster.
Create a branch or fork the following github repo:

https://github.com/solo-io/GlooOps

We will use this as a base in the following steps. 

Now we need to register the workload clusters to argo. For this exercise we will use the argocd command, however in production you may want to create the account and kubeconfig file manually. 


### Install gloo mesh mgmt plane and register workload clusters

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

TODO: document the template method

Run the following to generate the secrets to connect the cluster to the gloo mgmt plane:

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
This will do a few things:
- create a namespace gloo-mesh on the cluster
- store the tls certs and token as secrets on the client clusters as it needs it to comunicate with the management server.
  
Store the gloo-mesh endoint address:

```bash
export ENDPOINT_GLOO_MESH=$(kubectl --context ${MGMT} -n gloo-mesh get svc gloo-mesh-mgmt-server -o jsonpath='{.status.loadBalancer.ingress[0].*}'):9900
export HOST_GLOO_MESH=$(echo ${ENDPOINT_GLOO_MESH} | cut -d: -f1)
echo "---"
echo $ENDPOINT_GLOO_MESH
```

Register the workload clusters We do this by deploying an argo app that will manage the gloo client clusters
   
First Change the address of the mesh server in gloo client cluster 1 and 2
```bash  
sed -i '' "s/localhost:9900/${ENDPOINT_GLOO_MESH}/g" argo/gloo/agent-config/helm/gloo-client-cluster1.yaml
sed -i '' "s/localhost:9900/${ENDPOINT_GLOO_MESH}/g" argo/gloo/agent-config/helm/gloo-client-cluster2.yaml
```

Push the changes to your github repo:

```bash
git commit --all -m "change gloo mesh server endpoint"
git push origin main
````

Now create the argo app:
   
```bash
k apply --context ${MGMT} -f "argo/gloo/agent-config/agentconfig-app.yaml"
```

### Deploy the gateways and install istio

```bash
kubectl --context ${MGMT} apply -f "argo/gloo/gateways/cross-cluster-gateway.yaml"
```
Create the gateways on the workload clusters and setup the istio lifecycle manager to manage the istio installation on the workload clusters:
The bellow will deploy 

```bash
k apply --context mgmt -f argo/gloo/gateways/applicationset.yaml -n argocd
```


