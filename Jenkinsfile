pipeline {
    agent {
        node {
            label 'Maven'
        }
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean install'
            }
        }
    }
}
