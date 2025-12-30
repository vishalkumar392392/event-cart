pipeline {
    agent any

    environment {
        APP_NAME = "eventcart"
        JAR_FILE = "target/*.jar"
        DEPLOY_PATH = "/opt/eventcart"
        SERVER_USER = "ec2-user"
        SERVER_IP = "54.147.47.205"
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
                echo "🚀 Deploying to EC2 Server..."

                sh '''
                # Ensure folder exists
                ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "sudo mkdir -p ${DEPLOY_PATH} && sudo chown ${SERVER_USER} ${DEPLOY_PATH}"
                
                # Copy latest JAR
                scp -o StrictHostKeyChecking=no ${JAR_FILE} ${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/${APP_NAME}.jar
                
                # Update & restart service
                ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "
                    sudo systemctl stop ${APP_NAME} || true
                    sudo systemctl start ${APP_NAME}
                    sudo systemctl status ${APP_NAME} --no-pager
                "
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