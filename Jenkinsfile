pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    environment {
        SCANNER_HOME= tool 'sonarqube-scanner'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git credentialsId: 'github-cred', url: 'https://github.com/semever24/goldencat-bank-app.git'
            }
        }

        stage('Code Compile') {
            steps {
                sh "mvn compile"
            }
        }

        stage('Code Test') {
            steps {
                sh "mvn test"
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh "trivy fs --format table -o fs-report.html ."
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Bank-App \
                    -Dsonar.projectKey=Bank-App \
                    -Dsonar.java.binaries=target
                    """
                }
            }
        }

         stage('Code Build') {
            steps {
                sh "mvn package"
            }
        }

        stage('Publish Artifacts to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'maven-settings', jdk: 'jdk17', maven: 'maven3', traceability: true) {
                        sh "mvn deploy"
                }
            }
        }

        stage('Docker Build & Tag') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh "docker build -t semever/bank-app:${BUILD_NUMBER} ."
                    }
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh "trivy image --format table -o image-report.html semever/bank-app:${BUILD_NUMBER}"
            }
        }

        stage('Docker Push Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred', toolName: 'docker') {
                        sh "docker push semever/bank-app:${BUILD_NUMBER}"
                    }
                }
            }
        }

         stage('Deployed to K8s cluster') {
            steps {
                withKubeConfig(caCertificate: '',clusterName: 'sk-cluster',contextName: '',credentialsId: 'k8-cred',namespace: 'webapps') {
                        sh "kubectl apply -f ./k8s/deployment-service.yml"
                        sleep 30
                }
            }
        }

        stage('Post Deployment Verification') {
            steps {
                withKubeConfig(caCertificate: '',clusterName: 'sk-cluster',contextName: '',credentialsId: 'k8-cred',namespace: 'webapps') {
                        sh "kubectl get pods"
                        sh "kubectl get svc"
                }
            }
        }
    }
        // Email notification for CICD pipeline completion with Success/Failure status
        post {
                always {
                    script {
                        def jobName = env.JOB_NAME
                        def buildNumber = env.BUILD_NUMBER
                        def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
                        def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

                        def body = """
                        <html>
                        <body>
                            <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                                <h2>${jobName} - Build ${buildNumber}</h2>
                                <div style="background-color: ${bannerColor}; padding: 10px;">
                                    <h3 style="color: white;">
                                        Pipeline Status: ${pipelineStatus.toUpperCase()}
                                    </h3>
                                </div>
                                <p>
                                    Check the <a href="${BUILD_URL}">console output</a>.
                                </p>
                            </div>
                        </body>
                        </html>
                        """

                        emailext(
                            subject: "${jobName} - Build ${buildNumber} - ${pipelineStatus.toUpperCase()}",
                            body: body,
                            to: 'semever@gmail.com',
                            from: 'jenkins@example.com',
                            replyTo: 'jenkins@example.com',
                            mimeType: 'text/html'
                        )
                    }
                }
         }   
}