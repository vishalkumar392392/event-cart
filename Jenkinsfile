pipeline {
    agent {
        node {
            label 'Maven'
        }
    }

    parameters {
        gitParameter(
            name: 'BRANCH',
            type: 'PT_BRANCH',
            defaultValue: 'main',
            branchFilter: 'origin/(.*)',
            description: 'Select Git branch'
        )

        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'uat', 'prod'],
            description: 'Deployment environment'
        )

        string(
            name: 'IMAGE_NAME',
            defaultValue: 'eventcart',
            description: 'Docker image name'
        )

        string(
            name: 'REPLICAS',
            defaultValue: '1',
            description: 'Number of pod replicas'
        )

        string(
            name: 'REQUEST_CPU',
            defaultValue: '250m',
            description: 'CPU request'
        )

        string(
            name: 'REQUEST_MEMORY',
            defaultValue: '512Mi',
            description: 'Memory request'
        )
    }

    environment {
        PATH = "/opt/maven/bin:$PATH"
        AWS_ACCOUNT_ID = "221082203021"
        AWS_REGION = "us-east-1"
        IMAGE_TAG = "${BUILD_NUMBER}"
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${params.IMAGE_NAME}"
        NAMESPACE = "${params.ENVIRONMENT}"
    }

    stages {

        

        stage('Build & Test') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Code Quality - SonarQube') {
            environment {
                scannerHome = tool 'eventcart-sonar-scanner'
            }
            steps {
                withSonarQubeEnv(
                    installationName: 'sonarqube-server-local',
                    credentialsId: 'sonarqubeLocalhost'
                ) {
                    sh "${scannerHome}/bin/sonar-scanner"
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                sh """
                  aws ecr get-login-password --region ${AWS_REGION} \
                  | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                  docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                  docker push ${ECR_REPO}:${IMAGE_TAG}
                  docker rmi ${ECR_REPO}:${IMAGE_TAG} || true
                """
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                  aws eks update-kubeconfig --region ${AWS_REGION} --name eventcart-eks-01

                  export IMAGE=${ECR_REPO}:${IMAGE_TAG}
                  export NAMESPACE=${NAMESPACE}
                  export REPLICAS=${params.REPLICAS}
                  export REQUEST_CPU=${params.REQUEST_CPU}
                  export REQUEST_MEMORY=${params.REQUEST_MEMORY}

                  envsubst < k8s/deployment.yaml | kubectl apply -f -
                  kubectl apply -f k8s/service.yaml
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful to ${params.ENVIRONMENT}"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}