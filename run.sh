#!/bin/bash

# Variables
INSTANCE_IP="18.204.87.210"  
KEY_NAME="clikp.pem" 
ECR_REPOSITORY="my-repository"  
DOCKER_IMAGE_TAG="latest"  
AWS_ACCOUNT_ID="767398032219" 
REGION="us-east-1" 
HOST_PORT="9090"  
CONTAINER_PORT="8080"  

echo "Installing Docker on the EC2 instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME ec2-user@$INSTANCE_IP <<EOF
  sudo yum update -y
  sudo yum install -y docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo chkconfig docker on

  echo "Authenticating Docker with AWS ECR..."
  aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

  echo "Pulling Docker image from ECR..."
  sudo docker pull $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY:$DOCKER_IMAGE_TAG

  echo "Running Docker container..."
  sudo docker run -d -p $HOST_PORT:$CONTAINER_PORT $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY:$DOCKER_IMAGE_TAG
EOF

echo "access the application at http://$INSTANCE_IP:$HOST_PORT"

