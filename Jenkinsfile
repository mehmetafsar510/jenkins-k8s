pipeline {
	agent { label "master" }
	environment {
		PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
		AWS_REGION = "us-east-1"
		APP_REPO_NAME = "mehmetafsar510"
        APP_NAME = "phonebook"
        AWS_STACK_NAME = "MehmetK8s-Phonebook-App-${BUILD_NUMBER}"
        CFN_TEMPLATE="kubernetes-env-cfn.yml"
        CFN_KEYPAIR="the_doctor"
        HOME_FOLDER = "/home/ubuntu"
        GIT_FOLDER = sh(script:'echo ${GIT_URL} | sed "s/.*\\///;s/.git$//"', returnStdout:true).trim()
	}
	stages {
		stage('Build Docker Result Image') {
			steps {
				sh 'docker build -t phonebook:latest ${GIT_URL}#:result'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-results:latest'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-results:${BUILD_ID}'
				sh 'docker images'
			}
		}
        stage('Build Docker Update Image') {
			steps {
				sh 'docker build -t phonebook:latest ${GIT_URL}#:kubernetes'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-updates:latest'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-updates:${BUILD_ID}'
				sh 'docker images'
			}
		}
		stage('Push Result Image to Docker Hub') {
			steps {
				withDockerRegistry([ credentialsId: "dockerhub_id", url: "" ]) {
				sh 'docker push $APP_REPO_NAME/phonebook-updates:latest'
				sh 'docker push $APP_REPO_NAME/phonebook-updates:${BUILD_ID}'
				}
			}
		}
        stage('Push Update Image to Docker Hub') {
			steps {
				withDockerRegistry([ credentialsId: "dockerhub_id", url: "" ]) {
				sh 'docker push $APP_REPO_NAME/phonebook-results:latest'
				sh 'docker push $APP_REPO_NAME/phonebook-results:${BUILD_ID}'
				}
			}
		}
		stage('creating infrastructure for the Application') {
            steps {
                echo 'creating infrastructure for the Application'
                sh "aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${AWS_STACK_NAME} --capabilities CAPABILITY_IAM --template-body file://${CFN_TEMPLATE} --parameters ParameterKey=KeyPairName,ParameterValue=${CFN_KEYPAIR}"

            script {
                while(true) {
                        
                        echo "K8s master is not UP and running yet. Will try to reach again after 10 seconds..."
                        sleep(10)

                        ip = sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=k8s-master Name=tag-value,Values=${AWS_STACK_NAME} --query Reservations[*].Instances[*].[PublicIpAddress] --output text | sed "s/\\s*None\\s*//g"', returnStdout:true).trim()

                        if (ip.length() >= 7) {
                            echo "K8s Master Public Ip Address Found: $ip"
                            env.MASTER_INSTANCE_PUBLIC_IP = "$ip"
                            break
                        }
                    }
                }
            }
        }
        stage('Test the infrastructure') {
            steps {
                echo "Testing if the K8s cluster is ready or not Master Public Ip Address: ${MASTER_INSTANCE_PUBLIC_IP}"
            script {
                sshagent(credentials : ['my-ssh-key']) {
                    while(true) {
                        try {
                          sh 'ssh -t -t ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}" -o StrictHostKeyChecking=no kubectl get nodes | grep -i kube-worker-1'
                          echo "Successfully created K8s cluster."
                          break
                        }
                        catch(Exception) {
                          echo 'Could not create K8s cluster please wait'
                          sleep(5)   
                        }
                    }
                }
            }
        }
    }
        stage('Check the App File') {
            steps { 
                script {
				    sshagent(credentials : ['my-ssh-key']) {
                        sh 'ssh -t -t ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}" -o StrictHostKeyChecking=no https://github.com/mehmetafsar510/jenkins-k8s.git && chmod 777 start.sh && sh start.sh &&  \
sh deploy.sh || kubectl set image deployment/phonebook-deployment phonebook=mehmet/phonebook:${BUILD_ID} --record'
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