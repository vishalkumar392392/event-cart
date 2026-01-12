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
                sh 'mvn clean test'
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