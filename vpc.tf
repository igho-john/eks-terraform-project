provider "aws" {
  region = "ca-central-1"
}

data "aws_availability_zones" "azs" {}

variable "cidr_block" {
    description = "The CIDR block for the VPC"
    type        = string    
}
variable "private_subnets" {
    description = "List of CIDR blocks for private subnets"
    type        = list(string)    
}
variable "public_subnets" {
    description = "List of CIDR blocks for public subnets"
    type        = list(string)    
}       
module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0" 
  
  name            = "myapp-vpc"
  cidr            = var.cidr_block
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = "1"
  }
}