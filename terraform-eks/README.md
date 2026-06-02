# Terraform port of the eksctl EKS setup

Converted from `JENKINS-SONARQUBE-AWS-ECR-EKS-SECRET-MANAGER-SPRINGBOOT-END-TO-END-CI-CD-PIPELINE.docx`.

## What this provisions

| Doc step (eksctl/kubectl/helm) | Terraform file |
|---|---|
| `eksctl create cluster --name eventcart-eks-01 ... --with-oidc` | `eks.tf`, `vpc.tf` |
| `kubectl create namespace {dev,uat,prod}` | `namespaces.tf` |
| IAM policy `eks-secrets-manager-policy-2` | `irsa.tf` |
| `eksctl create iamserviceaccount ... eventcart-sa` (IRSA) | `irsa.tf` |
| `helm install csi-secrets-store secrets-store-csi-driver` | `secrets_store_csi.tf` |
| `kubectl apply -f aws-provider-installer.yaml` | `secrets_store_csi.tf` |
| `kubectl edit configmap aws-auth` (map Jenkins `eksctl` role) | `eks.tf` (`aws_auth_roles`) |

## Usage

```bash
# 1. Configure AWS creds (same as `aws configure` step in the doc)
aws sts get-caller-identity

# 2. Init + apply
terraform init
terraform apply

# 3. Wire kubectl to the cluster (replaces `aws eks update-kubeconfig`)
$(terraform output -raw update_kubeconfig_command)
kubectl get nodes
```

## Notable choices

- **VPC**: a fresh VPC is created via `terraform-aws-modules/vpc/aws`, mirroring what eksctl does by default (3 AZs, public+private subnets, single NAT). Swap to an existing VPC by editing `vpc.tf` if you want.
- **Kubernetes version**: defaulted to `1.31`. The doc mentions `1.35`, which is not a valid EKS version — set `cluster_version` in `terraform.tfvars` if you want a different supported version.
- **IRSA**: the doc only creates the `eventcart-sa` IRSA in the `dev` namespace. `var.irsa_namespaces` lets you extend it to `uat`/`prod` without copy-paste.
- **`aws-auth`**: the doc maps the Jenkins build-slave role `eksctl` into `system:masters`. The EKS module handles this via `aws_auth_roles`. Override the role name with `var.jenkins_build_slave_role_name`.
- **CSI AWS provider**: installed via Helm chart (version-pinned) instead of `kubectl apply` of a `main`-branch manifest.
