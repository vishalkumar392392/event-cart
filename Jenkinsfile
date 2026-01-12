pipeline {
    agent {
        node {
            label 'Maven'
        }
    }

    environment {
        PATH = "/opt/maven/bin:$PATH"
    }

    stages {

        stage('Build & Test') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Test Report') {
            steps {
                sh 'mvn surefire-report:report'
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
        
        stage('Upload Artifact to JFrog') {
    		steps {
        withCredentials([usernamePassword(
            credentialsId: 'jfrog-user-authentiation',
            usernameVariable: 'JFROG_USER',
            passwordVariable: 'JFROG_PASSWORD'
        )]) {
            sh '''
              echo "Uploading artifact to JFrog Artifactory..."

              curl -f -u "$JFROG_USER:$JFROG_PASSWORD" \
                -T target/eventcart-0.0.4-SNAPSHOT.jar \
                "http://172.31.45.86:8082/artifactory/libs-snapshot-local/eventcart/eventcart-0.0.4-SNAPSHOT.jar"
            '''
        }
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