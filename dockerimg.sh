#!/bin/bash

# Set variables
REGION="us-east-1"  
REPOSITORY_NAME="my-repository" 
DOCKER_IMAGE_NAME="spptclin"  

# Set AWS Region
export AWS_DEFAULT_REGION=$REGION

# 1. Authenticate Docker to Amazon ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws ecr describe-repositories --repository-name $REPOSITORY_NAME --query 'repositories[0].repositoryUri' --output text)

# 2. Build Docker Image
echo "Building Docker image..."
docker build -t $DOCKER_IMAGE_NAME .

# 3. Tag the Docker Image with the ECR URI
ECR_REPOSITORY_URI=$(aws ecr describe-repositories --repository-name $REPOSITORY_NAME --query 'repositories[0].repositoryUri' --output text)
docker tag $DOCKER_IMAGE_NAME:latest $ECR_REPOSITORY_URI:latest

# 4. Push the Docker Image to ECR
echo "Pushing Docker image to ECR..."
docker push $ECR_REPOSITORY_URI:latest

echo "Docker image pushed successfully to ECR!"

