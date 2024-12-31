#!/bin/bash

REGION="us-east-1"  
REPOSITORY_NAME="my-repository"  
DOCKER_IMAGE_NAME="spring-petclinic-new"  

export AWS_DEFAULT_REGION=$REGION

echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws ecr describe-repositories --repository-name $REPOSITORY_NAME --query 'repositories[0].repositoryUri' --output text)

echo "Building Docker image..."
docker build -t $DOCKER_IMAGE_NAME .

ECR_REPOSITORY_URI=$(aws ecr describe-repositories --repository-name $REPOSITORY_NAME --query 'repositories[0].repositoryUri' --output text)
docker tag $DOCKER_IMAGE_NAME:latest $ECR_REPOSITORY_URI:latest

echo "Pushing Docker image to ECR..."
docker push $ECR_REPOSITORY_URI:latest

echo "Docker image pushed successfully to ECR!"
