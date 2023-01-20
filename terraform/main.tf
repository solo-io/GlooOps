
#Create the base environment
module "environment" {
  source  = "app.terraform.io/jonaapelbaum/environment/aws"
  version = "v0.0.9"
  environmet_name= var.environmet_name
  vpc_region=var.aws_region
  created_by = var.created_by
  team   = var.team
  purpose = var.purpose
}

