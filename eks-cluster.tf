provider "kubernetes" {
  host                   = data.aws_eks_cluster.myapp_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.myapp_cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp_cluster.certificate_authority[0].data)
}

data "aws_eks_cluster" "myapp_cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "myapp_cluster" {
  name       = data.aws_eks_cluster.myapp_cluster.name
  depends_on = [module.eks]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name    = "myapp-eks-cluster"
  cluster_version = "1.31"

  cluster_endpoint_public_access  = true    
  cluster_endpoint_private_access = true    

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id     = module.myapp-vpc.vpc_id
  tags = {
    Environment = "dev"
    application = "myapp"
  }

  eks_managed_node_groups = {
    ng-1 = {                          # Node group 1 configuration
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }

    ng-2 = {                          # Node group 2 configuration
      instance_types = ["t3.medium"]
      desired_size   = 1
      min_size       = 1
      max_size       = 2
    }
  }
}