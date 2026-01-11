pipeline {
    agent {
        node {
            label 'Maven'
        }
    }

    environment {
        PATH = "/opt/maven/bin:$PATH"
        SONAR_PROJECT_KEY = "eventcart"
        SONAR_PROJECT_NAME = "eventcart"
    }

    stages {

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
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
    }

    post {
        success {
            echo '✅ Build and SonarQube analysis completed successfully'
        }
        failure {
            echo '❌ Build or SonarQube analysis failed'
        }
    }
}