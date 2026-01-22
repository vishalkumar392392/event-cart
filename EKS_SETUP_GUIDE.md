# EKS Cluster Setup Using eksctl

A comprehensive guide to create and manage an Amazon EKS cluster using the `eksctl` tool.

---

## Table of Contents

1. [Create EKS Cluster](#create-eks-cluster)
2. [Create Namespaces](#create-namespaces)
3. [Create IAM Policy](#create-iam-policy)
4. [Create IAM Service Account](#create-iam-service-account)
5. [Install CSI Driver](#install-csi-driver)
6. [Install AWS Provider](#install-aws-provider)
7. [Delete Cluster](#delete-cluster)

---

## Create EKS Cluster

Create an EKS cluster with OIDC provider enabled (required for IRSA):

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
  --with-oidc
```

### What This Creates

- VPC and Subnets
- EKS Control Plane
- Worker Node Group (2 nodes)
- OIDC provider for IRSA
- Required IAM roles and security groups

---

## Create Namespaces

Create separate Kubernetes namespaces for different environments:

```bash
kubectl create namespace dev
kubectl create namespace uat
kubectl create namespace prod
```

Verify the namespaces were created:

```bash
kubectl get ns
```

---

## Create IAM Policy

Create an IAM policy named `eks-secrets-manager-policy` to grant read permissions to AWS Secrets Manager.

> **Note:** Create this policy via the AWS Management Console

### Policy Document

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

## Create IAM Service Account

Create an IAM service account (IRSA) for the `dev` namespace with the necessary Secrets Manager permissions:

```bash
eksctl create iamserviceaccount \
  --cluster eventcart-eks-01 \
  --region us-east-1 \
  --name eventcart-sa \
  --namespace dev \
  --attach-policy-arn arn:aws:iam::221082203021:policy/eks-secrets-manager-policy \
  --approve
```

### Verify Service Account

```bash
kubectl get sa eventcart-sa -n dev -o yaml | grep eks.amazonaws.com
```

> **Tip:** Create similar service accounts for `uat` and `prod` namespaces by running the same command with different namespace values.

---

## Install CSI Driver

Install the Secrets Store CSI Driver using Helm:

### Add Helm Repository

```bash
helm repo add secrets-store-csi-driver \
  https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
```

### Update Repository

```bash
helm repo update
```

### Install CSI Driver

```bash
helm install csi-secrets-store \
  secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true
```

---

## Install AWS Provider

Install the AWS-specific provider for the Secrets Store CSI Driver:

```bash
kubectl apply -f \
  https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml
```

### Verify Installation

Check if the CSI driver pods are running:

```bash
kubectl get pods -n kube-system | grep secrets-store
```

Verify that the required CRDs are installed:

```bash
kubectl get crd | grep secretprovider
```

---

## Delete Cluster

> ⚠️ **Warning:** This will delete all resources associated with the cluster.

### Step 1: Delete Namespaces

```bash
kubectl delete namespace dev
kubectl delete namespace uat
kubectl delete namespace prod
```

### Step 2: Delete EKS Cluster

```bash
eksctl delete cluster --name eventcart-eks-01 --region us-east-1
```

---

## Additional Resources

- [eksctl Documentation](https://eksctl.io/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/)
- [AWS Provider for Secrets Store CSI Driver](https://github.com/aws/secrets-store-csi-driver-provider-aws)
