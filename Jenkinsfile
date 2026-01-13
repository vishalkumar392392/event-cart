pipeline {
    agent {
        node {
            label 'Maven'
        }
    }

    environment {
        PATH = "/opt/maven/bin:$PATH"
        AWS_ACCOUNT_ID = "221082203021"
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
        
        stage('Build & Push Docker Image to AWS ECR') {
    steps {
        sh '''
          echo "Logging in to AWS ECR..."
          aws ecr get-login-password --region us-east-1 \
          | docker login --username AWS --password-stdin \
            $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

          echo "Building Docker image..."
          docker build -t eventcart:${BUILD_NUMBER} .

          echo "Tagging image for ECR..."
          docker tag eventcart:${BUILD_NUMBER} \
            $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/eventcart:${BUILD_NUMBER}

          echo "Pushing image to ECR..."
          docker push \
            $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/eventcart:${BUILD_NUMBER}
        '''
    }
}

    }

    post {
        success {
            echo '✅ Build, Tests, and SonarQube analysis completed successfully'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}