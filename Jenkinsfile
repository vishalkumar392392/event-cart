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
        stage('Code Build') {
            steps {
                sh 'mvn clean install'
            }
        }
        stage('SonarQube analysis') {
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
}
