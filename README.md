# EKS Terraform Project

A production-ready Terraform project that provisions a complete AWS EKS (Kubernetes) environment including VPC, public/private subnets across 3 availability zones, NAT gateway, and a managed EKS cluster with two worker node groups.

---

## Architecture

![Alt text](/eks_terraform_architecture.svg)



```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
VPC (10.0.0.0/16) — ca-central-1
    ├── Public Subnets (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
    │       └── NAT Gateway (single)
    └── Private Subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
            └── EKS Cluster (myapp-eks-cluster)
                    ├── Node Group 1 — t3.medium (desired: 2, max: 3)
                    └── Node Group 2 — t3.medium (desired: 1, max: 2)
```

---

## Project Structure

```
eks-terraform-project/
├── vpc.tf                  # VPC, subnets, NAT gateway, route tables
├── eks-cluster.tf          # EKS cluster, node groups, kubernetes provider
├── versions.tf             # Provider version constraints
├── variables.tf            # Input variable declarations
├── outputs.tf              # Output values
└── terraform.tfvars        # Variable values (not committed to git)
```

---

## File Descriptions

| File | Description |
|---|---|
| `vpc.tf` | VPC module — 3 public and 3 private subnets across all AZs, single NAT gateway |
| `eks-cluster.tf` | EKS module — managed node groups, Kubernetes provider configuration |
| `versions.tf` | Pins AWS provider to `~> 5.81` and Kubernetes provider to `~> 2.0` |
| `variables.tf` | Declares `cidr_block`, `private_subnets`, `public_subnets` |
| `outputs.tf` | Exposes VPC ID, subnet IDs |
| `terraform.tfvars` | Your variable values — never commit this file |

---

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with valid credentials
- `kubectl` installed
- `helm` installed (optional)

Install all tools on Mac:
```bash
brew install terraform awscli kubectl helm eksctl
```

---

## Input Variables

| Variable | Type | Description |
|---|---|---|
| `cidr_block` | string | CIDR block for the VPC e.g. `10.0.0.0/16` |
| `private_subnets` | list(string) | List of private subnet CIDRs |
| `public_subnets` | list(string) | List of public subnet CIDRs |

---

## terraform.tfvars Example

```hcl
cidr_block      = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
```

---

## Usage

**1. Initialise:**
```bash
terraform init
```

**2. Preview:**
```bash
terraform plan -var-file="terraform.tfvars"
```

**3. Apply (takes 10-15 minutes):**
```bash
terraform apply -var-file="terraform.tfvars"
```

**4. Connect kubectl to your cluster:**
```bash
aws eks update-kubeconfig --name myapp-eks-cluster --region ca-central-1
```

**5. Verify nodes are running:**
```bash
kubectl get nodes
```

**6. Destroy all resources:**
```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | The ID of the VPC |
| `private_subnets` | List of private subnet IDs |
| `public_subnets` | List of public subnet IDs |

---

## Module Versions

| Module | Version |
|---|---|
| `terraform-aws-modules/vpc/aws` | `5.19.0` |
| `terraform-aws-modules/eks/aws` | `20.31.6` |
| AWS Provider | `~> 5.81` |
| Kubernetes Provider | `~> 2.0` |

---

## Security Notes

- EKS worker nodes run in **private subnets** — not directly accessible from internet
- NAT gateway allows nodes to pull images and updates outbound
- Never commit `terraform.tfvars` or `terraform.tfstate`
- Always run `terraform plan` before `terraform apply`

---

## .gitignore

```
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.tfplan
crash.log
```
