#!/bin/bash

# Variables
INSTANCE_IP="54.174.185.239" 
KEY_NAME="newkp.pem"  
ECR_REPOSITORY="my-repository"  
DOCKER_IMAGE_TAG="latest"  
AWS_ACCOUNT_ID="767398032219"  
REGION="us-east-1"  
HOST_PORT="8080"  
CONTAINER_PORT="8080"  

# Step 1: SSH into EC2 and install Docker
echo "Installing Docker on the EC2 instance..."
ssh -o StrictHostKeyChecking=no -i $KEY_NAME ec2-user@$INSTANCE_IP <<EOF
  sudo yum update -y
  sudo yum install -y docker
  sudo service docker start
  sudo usermod -a -G docker ec2-user
  sudo chkconfig docker on

  # Step 2: Authenticate Docker with AWS ECR
  echo "Authenticating Docker with AWS ECR..."
  aws ecr get-login-password --region $REGION | sudo docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

  # Step 3: Pull Docker image from ECR
  echo "Pulling Docker image from ECR..."
  sudo docker pull $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY:$DOCKER_IMAGE_TAG

  # Step 4: Run Docker container
  echo "Running Docker container..."
  sudo docker run -d -p $HOST_PORT:$CONTAINER_PORT $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY:$DOCKER_IMAGE_TAG
EOF

# Step 5: Provide access URL
echo "You can access the application at http://$INSTANCE_IP:$HOST_PORT"

