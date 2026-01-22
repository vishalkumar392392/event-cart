# Complete EKS Setup Using eksctl (Step by Step)

> Production-grade, ordered, copy-paste friendly checklist.
> If you follow exactly in this order, your setup will work.

---

## Prerequisites

Before starting, ensure you have the following tools installed and configured on your EC2 instance or local machine:

```bash
aws --version
eksctl version
kubectl version --client
```

### Required Configuration

- AWS CLI is configured: `aws configure`
- IAM user/role has `AdministratorAccess` (for learning purposes)

---

## Step 1: Create EKS Cluster (with OIDC Enabled)

Run the following command to create your EKS cluster:

```bash
eksctl create cluster \
  --name eventcart-eks-01 \
  --region us-east-1 \
  --version 1.29 \
  --nodegroup-name eventcart-ng \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 2 \
  --managed \
  --with-oidc \
  --ssh-access \
  --ssh-public-key ~/.ssh/id_rsa.pub
```

### What This Creates Automatically

- VPC
- Subnets
- Node security groups
- Worker IAM role
- OIDC provider (**CRITICAL for IRSA**)

### Verify Cluster

```bash
kubectl get nodes
kubectl get svc
```

---

## Step 2: Create Namespaces (Environments)

Create separate namespaces for different environments:

```bash
kubectl create namespace dev
kubectl create namespace uat
kubectl create namespace prod
```

Verify namespaces:

```bash
kubectl get ns
```

---

## Step 3: Create IAM Policy for Secrets Manager

Navigate to AWS Console and create a policy named `eks-secrets-manager-policy` with the following JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:221082203021:secret:aws-dev*"
    }
  ]
}
```

---

## Step 4: Create IRSA Service Account

> **Warning:** Do NOT attach policy to node role or eksctl role

Run the following command to create an IAM service account with proper OIDC trust:

```bash
eksctl create iamserviceaccount \
  --cluster eventcart-eks-01 \
  --region us-east-1 \
  --name eventcart-sa \
  --namespace dev \
  --attach-policy-arn arn:aws:iam::221082203021:policy/eks-secrets-manager-policy \
  --approve
```

### What This Creates

- IAM Role
- Trust policy with OIDC provider
- ServiceAccount annotation

### Verify Service Account

```bash
kubectl get sa eventcart-sa -n dev -o yaml | grep eks.amazonaws.com
```

---

## Step 5: Install Secrets Store CSI Driver

> **Warning:** Do NOT mix versions or manually install CRDs separately

Install the CSI Driver (includes CRDs):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v1.4.4/deploy/secrets-store-csi-driver.yaml
```

### Verify Installation

```bash
kubectl get pods -n kube-system | grep secrets-store
kubectl get crd | grep secrets-store
```

You should see these Custom Resource Definitions:

- `secretproviderclasses.secrets-store.csi.x-k8s.io`
- `secretproviderclasspodstatuses.secrets-store.csi.x-k8s.io`

---

## Step 6: Install AWS Provider

Install the AWS-specific provider for Secrets Store CSI Driver:

```bash
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
```

### Verify AWS Provider

```bash
kubectl get pods -n kube-system | grep aws
```

---

## Step 7: Apply Kubernetes Files

### Order Matters!

#### 7.1 Apply ServiceAccount

```bash
kubectl apply -f serviceaccount.yaml
```

> **Ensure** the `serviceAccountName: eventcart-sa` is specified in the YAML

#### 7.2 Apply SecretProviderClass

```bash
kubectl apply -f secretproviderclass.yaml
```

Verify:

```bash
kubectl get secretproviderclass -n dev
```

#### 7.3 Apply Deployment

```bash
kubectl apply -f deployment.yaml
```

#### 7.4 Apply Service

```bash
kubectl apply -f service.yaml
```

---

## Step 8: Verify Pod & Secrets

Check if pods are running:

```bash
kubectl get pods -n dev
kubectl describe pod -n dev <pod-name>
```

### Expected Results

- ❌ **NO** `FailedMount` errors
- ✅ Status should be `ContainerRunning`

Check environment variables:

```bash
kubectl exec -n dev <pod-name> -- printenv | grep DB_
```

---

## Step 9: Access Application

Retrieve the service endpoint:

```bash
kubectl get svc -n dev
```

Access the application:

```bash
curl http://<ELB-DNS>/wife
```

---

## What NOT to Do (Common Mistakes)

### ❌ Incorrect Practices

1. **Do NOT** attach SecretsManager policy to:
   - eksctl role
   - NodeGroup role

2. **Do NOT** manually install CRDs from random URLs

3. **Do NOT** mix Terraform + eksctl for IRSA

---

## Mental Model: Understanding the Architecture

| Layer               | Responsibility      |
| ------------------- | ------------------- |
| `eksctl`            | Cluster, OIDC, IRSA |
| IAM Policy          | Permissions         |
| ServiceAccount      | Identity            |
| CSI Driver          | Fetch secrets       |
| SecretProviderClass | Map secrets         |
| Pod                 | Consume env vars    |

---

## Conclusion

Yes — **ALL** of this is achievable using eksctl alone, and this is the **industry-preferred way** for EKS + Secrets Manager.

### Next Steps

After completing this guide, you can:

- Review your final YAML files for correctness
- Implement a production hardening checklist
- Convert setup to multi-environment (dev/uat/prod) cleanly

---

**Happy deploying! 🚀**
