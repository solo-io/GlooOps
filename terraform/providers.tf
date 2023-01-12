terraform {
  cloud {
    organization = "jonaapelbaum"

    workspaces {
      name = "argo-cd-demo"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
