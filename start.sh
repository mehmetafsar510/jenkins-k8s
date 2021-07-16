#! /bin/bash
chmod u+r+x /home/ubuntu/jenkins-k8s/deploy.sh
sed -i -e 's/\r$//' /home/ubuntu/jenkins-k8s/deploy.sh