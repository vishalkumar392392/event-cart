pipeline {
    agent any

    environment {
        APP_NAME = "eventcart"
        JAR_FILE = "target/*.jar"
        DEPLOY_PATH = "/opt/eventcart"
    }

    stages {

        stage('Build') {
            steps {
                echo "🔨 Building Spring Boot Application..."
                sh 'mvn clean install -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo "✔ Build Completed Successfully"
            }
        }

        stage('Deploy') {
            steps {
                echo "🚀 Deploying locally on same EC2 server..."

                sh '''
                    sudo mkdir -p ${DEPLOY_PATH}
                    sudo cp ${JAR_FILE} ${DEPLOY_PATH}/${APP_NAME}.jar

                    sudo systemctl stop ${APP_NAME} || true
                    sudo systemctl start ${APP_NAME}
                    sudo systemctl status ${APP_NAME} --no-pager
                '''

                echo "✔ Deployment Completed Successfully"
            }
        }
    }

    post {
        success {
            echo "🎉 SUCCESS: Build + Deployment Finished!"
        }
        failure {
            echo "❌ FAILURE: Check build logs!"
        }
    }
}