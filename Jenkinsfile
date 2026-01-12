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
        stage('test') {
            steps {
                sh 'mvn surefire-report:report'
            }
        }

        stage('Code Quality - SonarQube') {
            environment {
     			 scannerHome = tool 'eventcart-sonar-scanner'
    		}
            steps{
   				 withSonarQubeEnv('eventcart-sonarqube-server') { // If you have configured more than one global server connection, you can specify its name
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