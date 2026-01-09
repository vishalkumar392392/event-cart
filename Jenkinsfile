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
        stage('Build') {
            steps {
                sh 'mvn clean install'
            }
        }
    }
}
