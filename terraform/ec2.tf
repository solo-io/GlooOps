resource "aws_security_group" "vm-sg" {
  name = "${var.environmet_name}-vm-sg"
  vpc_id = module.environment.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
        from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
  depends_on = [
    aws_security_group.vm-sg
  ]
}

# resource "aws_instance" "minikube" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = var.instance_type
#   vpc_security_group_ids = [aws_security_group.vm-sg.id]
#   subnet_id = module.environment.public_sn[0]
#   key_name = var.key_name
#   tags = {
#     Name ="${var.environmet_name}-minikube"
#   }
#  depends_on = [
#    aws_security_group.vm-sg
#  ]
# }

# resource "aws_instance" "VM" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = var.instance_type
#   vpc_security_group_ids = [aws_security_group.vm-sg.id]
#   subnet_id = module.environment.public_sn[0]
#   key_name = var.key_name
#   tags = {
#     Name ="${var.environmet_name}-VM"
#   }
# }

# data aws_instance "minikube" {
#   instance_id = aws_instance.minikube.id

# }

# data aws_instance "VM" {
#   instance_id = aws_instance.VM.id
# }