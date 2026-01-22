Perfect 👍 — now we’ll reset cleanly and do everything the RIGHT way using only eksctl + kubectl, no Terraform, no half-installed CRDs, no confusion.

Below is a production-grade, ordered, copy-paste friendly checklist.
If you follow exactly in this order, your setup will work.

⸻

✅ COMPLETE EKS SETUP USING eksctl (STEP BY STEP)

⸻

🔰 PREREQUISITES (RUN ON YOUR EC2 / LOCAL MACHINE)

aws --version
eksctl version
kubectl version --client

👉 Make sure:
• AWS CLI is configured (aws configure)
• IAM user/role has AdministratorAccess (learning purpose is fine)

⸻

🟢 STEP 1: CREATE EKS CLUSTER (WITH OIDC ENABLED)

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

✅ This automatically creates:
• VPC
• Subnets
• Node security groups
• Worker IAM role
• OIDC provider (CRITICAL for IRSA)

⸻

🔎 VERIFY CLUSTER

kubectl get nodes
kubectl get svc

⸻

🟢 STEP 2: CREATE NAMESPACES (ENVIRONMENTS)

kubectl create namespace dev
kubectl create namespace uat
kubectl create namespace prod

kubectl get ns

⸻

🟢 STEP 3: CREATE IAM POLICY FOR SECRETS MANAGER

(You said console is fine ✅)

Policy name: eks-secrets-manager-policy

{
"Version": "2012-10-17",
"Statement": [
{
"Effect": "Allow",
"Action": [
"secretsmanager:GetSecretValue",
"secretsmanager:DescribeSecret"
],
"Resource": "arn:aws:secretsmanager:us-east-1:221082203021:secret:aws-dev\*"
}
]
}

⸻

🟢 STEP 4: CREATE IRSA SERVICE ACCOUNT (THIS IS THE KEY FIX)

⚠️ DO NOT attach policy to node role
⚠️ DO NOT attach policy to eksctl role

eksctl create iamserviceaccount \
 --cluster eventcart-eks-01 \
 --region us-east-1 \
 --name eventcart-sa \
 --namespace dev \
 --attach-policy-arn arn:aws:iam::221082203021:policy/eks-secrets-manager-policy \
 --approve

✅ This creates:
• IAM Role
• Trust policy with OIDC
• ServiceAccount annotation

Verify:

kubectl get sa eventcart-sa -n dev -o yaml | grep eks.amazonaws.com

⸻

🟢 STEP 5: INSTALL SECRETS STORE CSI DRIVER (CORRECT WAY)

⚠️ Do NOT mix versions
⚠️ Do NOT manually install CRDs separately

Install CSI Driver (includes CRDs)

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/v1.4.4/deploy/secrets-store-csi-driver.yaml

Verify:

kubectl get pods -n kube-system | grep secrets-store
kubectl get crd | grep secrets-store

You should see:
• secretproviderclasses.secrets-store.csi.x-k8s.io
• secretproviderclasspodstatuses.secrets-store.csi.x-k8s.io

⸻

🟢 STEP 6: INSTALL AWS PROVIDER (CRITICAL)

kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

Verify:

kubectl get pods -n kube-system | grep aws

⸻

🟢 STEP 7: APPLY K8s FILES (ORDER MATTERS)

7.1 ServiceAccount (must use IRSA-created SA)

kubectl apply -f serviceaccount.yaml

⚠️ Ensure:

serviceAccountName: eventcart-sa

⸻

7.2 SecretProviderClass

kubectl apply -f secretproviderclass.yaml

Verify:

kubectl get secretproviderclass -n dev

⸻

7.3 Deployment

kubectl apply -f deployment.yaml

⸻

7.4 Service

kubectl apply -f service.yaml

⸻

🟢 STEP 8: VERIFY POD & SECRETS

kubectl get pods -n dev
kubectl describe pod -n dev <pod-name>

You MUST see:
• ❌ NO FailedMount
• ✅ ContainerRunning

Check env vars:

kubectl exec -n dev <pod-name> -- printenv | grep DB\_

⸻

🟢 STEP 9: ACCESS APPLICATION

kubectl get svc -n dev

curl http://<ELB-DNS>/wife

⸻

🚫 WHAT YOU SHOULD NOT DO (YOUR OLD MISTAKES)

❌ Do NOT attach SecretsManager policy to:
• eksctl role
• NodeGroup role

❌ Do NOT manually install CRDs from random URLs

❌ Do NOT mix Terraform + eksctl for IRSA

⸻

🧠 FINAL MENTAL MODEL (IMPORTANT)

Layer Responsibility
eksctl Cluster, OIDC, IRSA
IAM Policy Permissions
ServiceAccount Identity
CSI Driver Fetch secrets
SecretProviderClass Map secrets
Pod Consume env vars

⸻

✅ CONCLUSION

Yes — ALL of this is achievable using eksctl alone, and this is the industry-preferred way for EKS + Secrets Manager.

If you want next, I can:
• Review your final YAMLs once
• Give you a production hardening checklist
• Convert this to multi-env (dev/uat/prod) cleanly

Just tell me 👍
