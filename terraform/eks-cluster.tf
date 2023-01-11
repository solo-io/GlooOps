module "eks_mgmt" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true
  cluster_name    = "${var.environmet_name}-mgmt"
  cluster_version = "1.24"

  vpc_id     = module.environment.vpc_id
  subnet_ids = module.environment.public_sn

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
  }

  eks_managed_node_groups = {
    one = {
      name = "mgmt-ng1"
      use_name_prefix = false
      instance_types = ["t3.large"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id
      ]
    }
  }
  tags = {
    created-by = var.created_by
    team   = var.team
    purpose = var.purpose
  }
}

module "eks_cluster1" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true
  cluster_name    = "${var.environmet_name}-cluster1"
  cluster_version = "1.24"

  vpc_id     = module.environment.vpc_id
  subnet_ids = module.environment.public_sn

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
  }

  eks_managed_node_groups = {
    one = {
      name = "cluster1-ng"
      use_name_prefix = false
      instance_types = ["t3.large"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id
      ]
    }
    
  }
  tags = {
    created-by = var.created_by
    team   = var.team
    purpose = var.purpose
  }
}

module "eks_cluster2" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.4"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access = true
  cluster_name    = "${var.environmet_name}-cluster2"
  cluster_version = "1.24"

  vpc_id     = module.environment.vpc_id
  subnet_ids = module.environment.public_sn

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

    attach_cluster_primary_security_group = true

    # Disabling and using externally provided security groups
    create_security_group = false
  }

  eks_managed_node_groups = {
    one = {
      name = "cluster2-ng"
      use_name_prefix = false
      instance_types = ["t3.large"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id
      ]
    }
  }
  tags = {
    created-by = var.created_by
    team   = var.team
    purpose = var.purpose
  }
}



