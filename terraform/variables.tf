variable "aws_region" {
  type = string
  description = "Default aws region to deploy into"
}

variable "environmet_name" {
  type = string
  description = "used as a prefix for resources created"
}

variable "instance_type" {
  description = "instance type for ec2"
  default   =  "t3.micro"
}

variable "key_name" {
  type=string
  default = "jona-solo"
}

#team name variable
variable "team" {
  type = string
  description = "team name"
}


#purpose variable
variable "purpose" {
  type = string
  description = "purpose of the deployment"
}

#created by variable
variable "created_by" {
  type = string
  description = "who created the deployment"
}