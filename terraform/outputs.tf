#the public of minikube
# output "minikube_public_ip" {
#  value = data.aws_instance.minikube.public_ip
# }

# output "VM_public_ip" {
#  value = data.aws_instance.VM.public_ip
# }

output "eks_mgmt" {
    value = module.eks_mgmt.cluster_id
}

output "eks_cluster1" {
    value = module.eks_cluster1.cluster_id
}

output "eks_cluster2" {
    value = module.eks_cluster2.cluster_id
}

# output "vm_instanceid" {
#     value = data.aws_instance.VM.instance_id
# }

# output "minikube_instanceid" {
#     value = data.aws_instance.minikube.instance_id
# }