# EKS Terraform Project

A production-ready Terraform project that provisions a complete AWS EKS (Kubernetes) environment including VPC, public/private subnets across 3 availability zones, NAT gateway, a managed EKS cluster with two worker node groups, and an Nginx application deployed via Kubernetes.

---

## Architecture

![Alt text](/eks_nginx_architecture.svg)

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
AWS Load Balancer (type: LoadBalancer — port 80)
    │
    ▼
VPC (10.0.0.0/16) — ca-central-1
    ├── Public Subnets (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
    │       └── NAT Gateway (single)
    └── Private Subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
            └── EKS Cluster (myapp-eks-cluster)
                    ├── Control Plane (managed by AWS)
                    ├── Node Group 1 — t3.medium (desired: 2, max: 3)
                    ├── Node Group 2 — t3.medium (desired: 1, max: 2)
                    └── Nginx Deployment
                            ├── nginx-deployment.yaml (replicas: 2, image: nginx:latest)
                            └── nginx-service.yaml (type: LoadBalancer, port: 80)
```

---

## Project Structure

```
eks-terraform-project/
├── vpc.tf                       # VPC, subnets, NAT gateway, route tables
├── eks-cluster.tf               # EKS cluster, node groups, kubernetes provider
├── versions.tf                  # Provider version constraints
├── variables.tf                 # Input variable declarations
├── outputs.tf                   # Output values
├── nginx-deployment.yaml        # Nginx Kubernetes deployment
├── nginx-service.yaml           # Nginx Kubernetes LoadBalancer service
└── terraform.tfvars             # Variable values (not committed to git)
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
| `nginx-deployment.yaml` | Kubernetes deployment — 2 replicas of nginx:latest on port 80 |
| `nginx-service.yaml` | Kubernetes service — exposes nginx via AWS Load Balancer on port 80 |
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

**6. Deploy Nginx:**
```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
```

**7. Check pods are running:**
```bash
kubectl get pods
```

**8. Get the Load Balancer URL:**
```bash
kubectl get service nginx-service
```
Open the `EXTERNAL-IP` in your browser to see the Nginx welcome page.

**9. Destroy all resources (always delete k8s resources first):**
```bash
kubectl delete service nginx-service
kubectl delete deployment nginx-deployment
terraform destroy -var-file="terraform.tfvars"
```

---

## Nginx Deployment

**nginx-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

**nginx-service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
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
- Always delete Kubernetes resources before running `terraform destroy`

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
