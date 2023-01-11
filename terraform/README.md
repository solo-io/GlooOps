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
```
Create the git repo for argo:
Navigate to the repo directory
run
```bash
helm show crds gloo-mesh-enterprise/gloo-mesh-enterprise > gloocrds.yaml

helm template gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise --devel --debug \
--namespace gloo-mesh \
--version=2.1.0 \
--set glooMeshMgmtServer.ports.healthcheck=8091 \
--set registerMgmtPlane.enabled=true \
--set registerMgmtPlane.ext-auth-service.enabled=true \
--set glooMeshUi.serviceType=LoadBalancer \
--set mgmtClusterName=mgmt \
--set global.cluster=mgmt \
--set licenseKey=${GLOO_MESH_LICENSE_KEY} \
--set verbose=true \
--include-crds \
--output-dir ./test
```
kustomize create --autodetect  


5. Run
```bash
k apply -n argocd -f argo/gloo/mgmt-server/appproject.yaml --context ${MGMT}


k apply -n argocd -f /Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/mgmt-server/template/app-mgmt-server.yaml --context ${MGMT}
```
Wait for deployment to finish (check Argo)
6. Run the following to generate the secrets to connect the cluster to the gloo mgmt plane:
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
8. 
```bash
argocd login a56e7e4e152f344aebeafe3d5b8e61f9-254401366.eu-west-3.elb.amazonaws.com
argocd cluster add cluster1 
argocd cluster add cluster2
````
helm template gloo-mesh-agent gloo-mesh-agent/gloo-mesh-agent --devel --debug \
  --namespace gloo-mesh \
  --kube-context=${CLUSTER1} \
  --set relay.serverAddress=${ENDPOINT_GLOO_MESH} \
  --set relay.authority=gloo-mesh-mgmt-server.gloo-mesh \
  --set rate-limiter.enabled=false \
  --set ext-auth-service.enabled=false \
  --set cluster=cluster1 \
  --version 2.1.0 \
  --include-crds \
  --output-dir ./

k apply --context cluster1 -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/agent-config/argo/template/crds"

k apply --context cluster2 -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/agent-config/argo/template/crds"

k apply -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/agent-config/argo/template/k8scluster1.yaml" --context ${MGMT} 
k apply -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/agent-config/argo/template/k8scluster2.yaml" --context ${MGMT} 
```
9.
Change the address of the mesh server in gloo client cluster 1 and 2
```bash  
k apply --context ${MGMT} -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/agent-config/gloo-cluster1.yaml"
k apply --context ${MGMT} -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/agent-config/gloo-cluster1.yaml"

k apply --context ${MGMT} -f ""
```
1.  
```bash
kubectl --context ${MGMT} apply -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/gateways/cross-cluster-gateway.yaml"
```
11.
```bash
kubectl --context ${CLUSTER1} create ns istio-gateways
kubectl --context ${CLUSTER1} apply -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/gateways/cluster1"
kubectl --context ${CLUSTER2} create ns istio-gateways
kubectl --context ${CLUSTER2} apply -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/gateways/cluster2"
```
12.
```bash
kubectl --context ${MGMT} apply -f "/Users/jona/Documents/git/customers/gloo-eks/terraform/argo/gloo/istio-lifecycle"
```


