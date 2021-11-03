pipeline {
	agent any
	environment {
		PATH=sh(script:"echo $PATH:/usr/local/bin", returnStdout:true).trim()
		AWS_REGION = "us-east-1"
		APP_REPO_NAME = "mehmetafsar510"
        APP_NAME = "phonebook"
        APP_STACK_NAME = "MehmetK8s-Phonebook-App"
        CFN_TEMPLATE="kubernetes-env-cf.yml"
        CFN_KEYPAIR="doctor"
        HOME_FOLDER = "/home/ubuntu"
        GIT_FOLDER = sh(script:'echo ${GIT_URL} | sed "s/.*\\///;s/.git$//"', returnStdout:true).trim()
	}
	stages {
		stage('Build Docker Result Image') {
			steps {
				sh 'docker build -t phonebook:latest ${GIT_URL}#:result'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-result:latest'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-result:${BUILD_ID}'
				sh 'docker images'
			}
		}
        stage('Build Docker Update Image') {
			steps {
				sh 'docker build -t phonebook:latest ${GIT_URL}#:kubernetes'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-update:latest'
				sh 'docker tag phonebook:latest $APP_REPO_NAME/phonebook-update:${BUILD_ID}'
				sh 'docker images'
			}
		}
		stage('Push Result Image to Docker Hub') {
			steps {
				withDockerRegistry([ credentialsId: "dockerhub_id", url: "" ]) {
				sh 'docker push $APP_REPO_NAME/phonebook-update:latest'
				sh 'docker push $APP_REPO_NAME/phonebook-update:${BUILD_ID}'
				}
			}
		}
        stage('Push Update Image to Docker Hub') {
			steps {
				withDockerRegistry([ credentialsId: "dockerhub_id", url: "" ]) {
				sh 'docker push $APP_REPO_NAME/phonebook-result:latest'
				sh 'docker push $APP_REPO_NAME/phonebook-result:${BUILD_ID}'
				}
			}
		}
        stage('get-keypair'){
            agent any
            steps{
                sh '''
                    if [ -f "${CFN_KEYPAIR}.pem" ]
                    then 
                        echo "file exists..."
                    else
                        aws ec2 create-key-pair \
                          --region ${AWS_REGION} \
                          --key-name ${CFN_KEYPAIR} \
                          --query KeyMaterial \
                          --output text > ${CFN_KEYPAIR}.pem
                        chmod 400 ${CFN_KEYPAIR}.pem
                        
                        ssh-keygen -y -f ${CFN_KEYPAIR}.pem >> ${CFN_KEYPAIR}.pub
                        cp -f ${CFN_KEYPAIR}.pem ${JENKINS_HOME}/.ssh
                        chown jenkins:jenkins ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem
                    fi
                '''                
            }
        }
		stage('creating infrastructure for the Application') {
            steps {
                echo 'creating infrastructure for the Application'
                
                sh '''
                    MasterIp=$(aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=k8s-master Name=tag-value,Values=${APP_STACK_NAME} --query Reservations[*].Instances[*].[PublicIpAddress] --output text)  || true
                    if [ "$MasterIp" == '' ]
                    then
                        aws cloudformation create-stack --stack-name ${APP_STACK_NAME} \
                          --capabilities CAPABILITY_IAM \
                          --template-body file://${CFN_TEMPLATE} \
                          --region ${AWS_REGION} --parameters ParameterKey=KeyPairName,ParameterValue=${CFN_KEYPAIR} 
                          
                        
                    fi
                '''
            script {
                while(true) {
                        
                        echo "K8s master is not UP and running yet. Will try to reach again after 10 seconds..."
                        sleep(10)

                        ip = sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=k8s-master Name=tag-value,Values=${APP_STACK_NAME} --query Reservations[*].Instances[*].[PublicIpAddress] --output text | sed "s/\\s*None\\s*//g"', returnStdout:true).trim()

                        if (ip.length() >= 7) {
                            echo "K8s Master Public Ip Address Found: $ip"
                            env.MASTER_INSTANCE_PUBLIC_IP = "$ip"
                            break
                        }
                    }
                while(true) {
                        
                        echo "Kube Master is not UP and running yet. Will try to reach again after 10 seconds..."
                        sleep(5)

                        ip = sh(script:'aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=k8s-master  --query Reservations[*].Instances[*].[PrivateIpAddress] --output text | sed "s/\\s*None\\s*//g"', returnStdout:true).trim()

                        if (ip.length() >= 7) {
                            echo "Kube Master Private Ip Address Found: $ip"
                            env.MASTER_INSTANCE_PRIVATE_IP = "$ip"
                            sleep(5)
                            break
                        }
                    }
                }
            }
        }
        stage('Test the infrastructure') {
            steps {
                echo "Testing if the K8s cluster is ready or not Master Public Ip Address: ${MASTER_INSTANCE_PUBLIC_IP}"
                script {                                                                // sshagent(credentials : ['my-ssh-key']) 
                        while(true) {
                            try {
                              sh 'ssh -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}" -o StrictHostKeyChecking=no kubectl get nodes | grep -i kube-worker-1'
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
        stage('Apply the App File') {
            steps {
                echo "Copy the config file"
                sh "mkdir -p ${JENKINS_HOME}/.kube"
                sh '''scp -o StrictHostKeyChecking=no \
                        -o UserKnownHostsFile=/dev/null \
                        -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem -q ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}":/home/ubuntu/.kube/config ${JENKINS_HOME}/.kube/
                    '''
                sh "chmod 775 ${JENKINS_HOME}/.kube/config"
                sh "sed -i 's/$MASTER_INSTANCE_PRIVATE_IP/$MASTER_INSTANCE_PUBLIC_IP/' ${JENKINS_HOME}/.kube/config"
                sh 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}" sudo rm -f /etc/kubernetes/pki/apiserver.*'
                sh 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}" sudo kubeadm init phase certs all --apiserver-advertise-address=0.0.0.0 --apiserver-cert-extra-sans=$MASTER_INSTANCE_PRIVATE_IP,$MASTER_INSTANCE_PUBLIC_IP'
                sh "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem ubuntu@\'${MASTER_INSTANCE_PUBLIC_IP}' bash ssl-script"
                sh 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${JENKINS_HOME}/.ssh/${CFN_KEYPAIR}.pem ubuntu@\"${MASTER_INSTANCE_PUBLIC_IP}" sudo systemctl restart kubelet'
                sh "chmod 400 ${JENKINS_HOME}/.kube/config"
                sh "kubectl apply -f kubernetes"
                sh "kubectl apply -f result"                       
            }
        }
	}
 	post {
        	always {
            	echo 'Deleting all local images'
            	sh 'docker image prune -af'
        	}
            failure { 
                echo 'Deleting Cloudformation Stack due to the Failure'
                sh 'aws cloudformation delete-stack --region ${AWS_REGION} --stack-name ${AWS_STACK_NAME}'
            }
	}
}