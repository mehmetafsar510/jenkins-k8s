pipeline {
	agent { label "master" }
	environment {
		PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
        APP_FILE = fileExists "/home/ubuntu/jenkins-kubernetes-deploy"
		AWS_REGION = "us-east-1"
		APP_REPO_NAME = "clarusway-repo/phonebook-app"
        APP_NAME = "phonebook"
        AWS_STACK_NAME = "Mehmet-Phonebook-App-${BUILD_NUMBER}"
        CFN_TEMPLATE="kubernetes-cfn.yml"
        CFN_KEYPAIR="the_doctor"
        HOME_FOLDER = "/home/ubuntu"
        GIT_FOLDER = sh(script:'echo ${GIT_URL} | sed "s/.*\\///;s/.git$//"', returnStdout:true).trim()
	}
	stages {
		stage('Build Docker Image') {
			steps {
				sh 'docker build -t phonebook:latest https://github.com/talha-01/jenkins-kubernetes-deploy.git'
				sh 'docker tag phonebook:latest $APP_REPO_NAME:latest'
				sh 'docker tag phonebook:latest $APP_REPO_NAME:${BUILD_ID}'
				sh 'docker images'
			}
		}
		stage('Push Image to Docker Hub') {
			steps {
				withDockerRegistry([ credentialsId: "dockerhub", url: "" ]) {
				sh 'docker push $APP_REPO_NAME:latest'
				sh 'docker push $APP_REPO_NAME:${BUILD_ID}'
				}
			}
		}
		stage('creating infrastructure for the Application') {
            steps {
                echo 'creating infrastructure for the Application'
                sh "aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${AWS_STACK_NAME} --capabilities CAPABILITY_IAM --template-body file://${CFN_TEMPLATE} --parameters ParameterKey=KeyPairName,ParameterValue=${CFN_KEYPAIR}"

            script {
                while(true) {
                        
                        echo "Docker Grand Master is not UP and running yet. Will try to reach again after 10 seconds..."
                        sleep(10)

                        ip = sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=docker-grand-master Name=tag-value,Values=${AWS_STACK_NAME} --query Reservations[*].Instances[*].[PublicIpAddress] --output text | sed "s/\\s*None\\s*//g"', returnStdout:true).trim()

                        if (ip.length() >= 7) {
                            echo "Docker Grand Master Public Ip Address Found: $ip"
                            env.MASTER_INSTANCE_PUBLIC_IP = "$ip"
                            break
                        }
                    }
                }
            }
        }
        stage('Check the App File') {
			environment {
                MASTER_PUBLİC_IP=sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=k8s-master Name=tag-value,Values=${AWS_STACK_NAME} --query Reservations[*].Instances[*].[PublicIpAddress] --output text', returnStdout:true).trim()
            }
            steps { 
                script {
				    sshagent(credentials : ['talha-virginia']) {
                        sh "ssh -t -t ubuntu@${MASTER_PUBLİC_IP} -o StrictHostKeyChecking=no 'git clone https://github.com/talha-01/jenkins-kubernetes-deploy.git && \
kubectl apply -f jenkins-kubernetes-deploy/kubernetes || \
kubectl set image deployment/phonebook-deployment phonebook=talhas/phonebook:${BUILD_ID} --record'"
                     }
                }
            }
        }
	}
 	post {
        	always {
            		echo 'Deleting all local images'
            	sh 'docker image prune -af'
        	}
	}
}