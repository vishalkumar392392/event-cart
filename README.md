# EventCart - End-to-End DevOps Pipeline Demo

<img width="1157" height="632" alt="image" src="https://github.com/user-attachments/assets/2948a334-f7ae-4ee6-99f4-9f46c7dffa83" />


## Overview

**EventCart** is a Spring Boot application designed as a learning project to demonstrate a complete end-to-end DevOps pipeline. This project showcases best practices and tools used in modern cloud-native application deployment and continuous integration/continuous deployment (CI/CD) workflows.

> **Note**: This is a demo project with dummy APIs created primarily to learn and practice the DevOps flow rather than providing production-ready functionality.

## 📋 Project Purpose

This project serves as a practical learning platform for:

- Building containerized applications using Docker
- Implementing CI/CD pipelines with Jenkins
- Code quality analysis with SonarQube
- Infrastructure automation on AWS
- Container image management with Amazon ECR (Elastic Container Registry)
- Kubernetes orchestration with AWS EKS (Elastic Kubernetes Service)
- Infrastructure-as-Code for cloud deployments

## 🏗️ Architecture Overview

```
Developer Code Push
        ↓
   Git Repository
        ↓
   Jenkins Pipeline
        ├─ Build & Test (Maven)
        ├─ Code Quality (SonarQube)
        ├─ Quality Gate
        └─ Build & Push Docker Image (AWS ECR)
        ↓
   AWS EKS Cluster
        └─ Deploy Application
```

## 🛠️ Technology Stack

### Core Application

- **Framework**: Spring Boot 4.0.1
- **Language**: Java 17
- **Build Tool**: Maven

### DevOps & Infrastructure

- **CI/CD**: Jenkins
- **Code Quality**: SonarQube
- **Containerization**: Docker (Alpine Linux + Amazon Corretto 21)
- **Container Registry**: AWS ECR (Elastic Container Registry)
- **Orchestration**: AWS EKS (Elastic Kubernetes Service)
- **Cloud Provider**: AWS
- **IaC**: Kubernetes manifests (YAML)

### AWS Services

- **EKS**: Kubernetes cluster management
- **ECR**: Docker image repository
- **EC2**: Compute instances

## 📦 Project Structure

```
eventcart/
├── src/
│   ├── main/
│   │   ├── java/com/eventcart/
│   │   │   ├── EventcartApplication.java
│   │   │   └── controllers/
│   │   │       └── HelloWorldController.java
│   │   └── resources/
│   │       ├── application.properties
│   │       ├── static/
│   │       └── templates/
│   └── test/
│       └── java/com/eventcart/
├── k8s/
│   ├── deployment.yaml      # Kubernetes Deployment manifest
│   └── service.yaml         # Kubernetes Service manifest
├── Dockerfile               # Docker image configuration
├── Jenkinsfile             # CI/CD pipeline definition
├── pom.xml                 # Maven project configuration
├── sonar-project.properties # SonarQube configuration
└── bash-script-*.sh        # Infrastructure setup scripts
```

## 🚀 Getting Started

### Prerequisites

- **Java 17** or higher
- **Maven 3.6+**
- **Docker** (for local containerization)
- **kubectl** (for Kubernetes management)
- **AWS CLI** (for AWS operations)
- **Jenkins** (for running the CI/CD pipeline)
- **Terraform** (for infrastructure provisioning)

### AWS EKS Cluster Setup

Before deploying the application to EKS, you need to create the AWS EKS cluster using Terraform.

#### 1. Create EKS Cluster with Terraform

Use the provided Terraform script to create your EKS cluster:

- **Reference**: [V6-EKS-CLUSTER-CREATION.tf](https://github.com/vishalkumar392392/terraform/blob/main/terraform_code/vpc/V6-EKS-CLUSTER-CREATION.tf)

Execute the Terraform configuration:

```bash
# Navigate to your Terraform directory
cd terraform_code/vpc/

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan

# Apply the configuration (this creates the EKS cluster)
terraform apply
```

#### 2. Create Kubernetes Namespaces

After the EKS cluster is created, create the three environments as Kubernetes namespaces:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eventcart-eks-01

# Create namespaces for different environments
kubectl create namespace dev
kubectl create namespace uat
kubectl create namespace prod

# Verify namespaces
kubectl get namespaces
```

#### 3. Configure IAM Role in AWS Auth ConfigMap

To allow your Jenkins build-slave or bootstrap server to execute kubectl commands, you need to add the IAM role to the EKS cluster's aws-auth ConfigMap.

**From the machine where the EKS cluster was created:**

```bash
# Edit the aws-auth ConfigMap
kubectl edit configmap -n kube-system aws-auth

# Add the IAM role under the "mapRoles" section:
# Example - Add this to the existing mapRoles list:
```

Add the following YAML configuration to the `mapRoles` section:

```yaml
mapRoles: |
  - rolearn: arn:aws:iam::221082203021:role/eksctl
    username: eksctl
    groups:
      - system:masters
```

**Complete aws-auth ConfigMap Example:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::221082203021:role/eksctl
      username: eksctl
      groups:
        - system:masters
    # Add other roles as needed
```

**Verification:**

```bash
# Verify the ConfigMap was updated
kubectl get configmap -n kube-system aws-auth -o yaml

# Test kubectl access from build-slave/bootstrap server
kubectl get nodes
kubectl get pods --all-namespaces
```

**Important Notes:**

- Replace `221082203021` with your actual AWS Account ID
- The IAM role must exist in your AWS account
- The user/role running kubectl commands must be able to assume the IAM role
- After updating aws-auth ConfigMap, it may take a few seconds for the changes to take effect

### Local Development

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd eventcart
   ```

2. **Build the application**

   ```bash
   mvn clean install
   ```

3. **Run the application**

   ```bash
   mvn spring-boot:run
   ```

   The application will start on `http://localhost:8080`

4. **Test the API**
   ```bash
   curl http://localhost:8080/api/hello
   ```

## 🔄 CI/CD Pipeline

### Jenkins Pipeline Stages

The Jenkinsfile defines the following automated stages:

1. **Build & Test**
   - Runs `mvn clean install`
   - Compiles source code and runs unit tests

2. **Code Quality - SonarQube**
   - Analyzes code quality
   - Checks for code smells, bugs, and vulnerabilities
   - Uses SonarQube Scanner

3. **Quality Gate**
   - Waits for SonarQube quality gate results
   - Blocks pipeline if quality standards not met (timeout: 10 minutes)

4. **Build & Push Docker Image**
   - Builds Docker image with tag based on Jenkins build number
   - Authenticates with AWS ECR
   - Pushes image to ECR repository
   - Cleans up local image after push

5. **Deploy to EKS**
   - Updates kubeconfig for EKS cluster
   - Substitutes environment variables into Kubernetes manifests
   - Applies Deployment and Service manifests

### Jenkins Parameters

The pipeline accepts the following parameters:

| Parameter        | Type       | Default   | Description                         |
| ---------------- | ---------- | --------- | ----------------------------------- |
| `BRANCH`         | Git Branch | main      | Git branch to build                 |
| `ENVIRONMENT`    | Choice     | dev       | Target environment (dev, uat, prod) |
| `IMAGE_NAME`     | String     | eventcart | Docker image name                   |
| `REPLICAS`       | String     | 1         | Number of Kubernetes pod replicas   |
| `REQUEST_CPU`    | String     | 250m      | CPU request per pod                 |
| `REQUEST_MEMORY` | String     | 512Mi     | Memory request per pod              |

### AWS Configuration

The pipeline uses the following AWS configuration:

- **AWS Account ID**: 221082203021
- **AWS Region**: us-east-1
- **ECR Repository**: `<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/eventcart`
- **EKS Cluster**: eventcart-eks-01

## 🐳 Docker Configuration

The application is containerized using Amazon Corretto 21 (AWS-managed OpenJDK distribution) on Alpine Linux for a minimal image footprint.

**Dockerfile Highlights:**

- Base Image: `amazoncorretto:21-alpine`
- Exposed Port: 8080
- JAR File: `eventcart-0.0.4-SNAPSHOT.jar`

## ☸️ Kubernetes Deployment

### Deployment Configuration

The Kubernetes Deployment includes:

- **Replicas**: Configurable (default: 1)
- **Update Strategy**: Rolling update with max surge of 1 and max unavailable of 1
- **Resource Management**:
  - Requests: Configurable CPU and Memory
  - Limits: 500m CPU, 1024Mi Memory
- **Container Port**: 8080

### Service Configuration

The Kubernetes Service provides:

- **Type**: LoadBalancer (exposes application externally)
- **Load Balancer Type**: Network Load Balancer (NLB)
- **Port Mapping**: 80 (external) → 8080 (internal)

## 🔧 Infrastructure Setup Scripts

The following bash scripts are provided for infrastructure automation:

1. **bash-script-ec2-user-data-jfrog-installation.sh**
   - Automates JFrog Artifactory setup on EC2

2. **bash-script-ec2-user-data-to-install-sonarqube-in-ec2-instance.sh**
   - Automates SonarQube installation on EC2

3. **bash-script-setup-jenkins-ipv4-auto-update.sh**
   - Configures Jenkins IPv4 auto-update

## 📊 Code Quality

The project is configured with SonarQube for continuous code quality monitoring:

- **Scanner**: SonarQube Scanner
- **Configuration File**: `sonar-project.properties`
- **Integration**: Integrated into Jenkins pipeline with quality gate checks

## 🌐 API Endpoints

Currently, the application includes dummy APIs for demonstration:

- **GET** `/api/hello` - Sample endpoint for testing
- _More endpoints can be added for learning purposes_

## 📝 Environment-Specific Deployments

The pipeline supports deployments to different environments:

- **dev**: Development environment for testing
- **uat**: User Acceptance Testing environment
- **prod**: Production environment

Each environment can have different configurations (replicas, resource limits, etc.) through Jenkins parameters.

## 🔐 AWS Permissions Required

The Jenkins agent requires the following AWS IAM permissions:

- ECR: Create/push images to repositories
- EKS: Update kubeconfig and manage cluster resources
- EC2: Manage compute instances (if needed)

## 📚 Learning Objectives

This project helps you understand:

1. ✅ Spring Boot application development
2. ✅ Maven build automation
3. ✅ Docker containerization
4. ✅ CI/CD pipeline design with Jenkins
5. ✅ Code quality metrics with SonarQube
6. ✅ Container registry management (ECR)
7. ✅ Kubernetes orchestration (EKS)
8. ✅ AWS infrastructure integration
9. ✅ Infrastructure-as-Code principles
10. ✅ End-to-end DevOps workflow

## 🚧 Future Enhancements

- Add database integration (MySQL, PostgreSQL)
- Implement more realistic API endpoints
- Add API documentation (Swagger/OpenAPI)
- Configure monitoring and logging (CloudWatch, ELK)
- Add helm charts for advanced Kubernetes management
- Implement automated rollback strategies
- Add performance testing in the pipeline
- Configure auto-scaling policies

## 📖 Resources & Documentation

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

This is a learning project. Feel free to:

- Fork and experiment
- Add new features or APIs
- Improve the CI/CD pipeline
- Enhance documentation

## 📄 License

This project is open source and available for educational purposes.

## ✍️ Author

Created as an end-to-end DevOps learning project.

---

**Happy Learning! 🚀**

For questions or improvements, feel free to explore the codebase and Jenkins pipeline configuration.
