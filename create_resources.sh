**Write one or several bash scripts (using AWS CLI) which:
Create VPC, Subnet, Elastic Container Registry (ECR), EC2 instance, public IP address for EC2 instance, Security Groups**

#!/bin/bash

VPC_CIDR_BLOCK="10.0.0.0/16"
SUBNET_CIDR_BLOCK="10.0.1.0/24"
AVAILABILITY_ZONE="us-east-1a"  
AMI_ID="ami-01816d07b1128cd2d"  
INSTANCE_TYPE="t2.micro"
KEY_NAME="clikp.pem"
REGION="us-east-1"  
SG_NAME="MySecurityGroupcli"
REPOSITORY_NAME="my-repository"

export AWS_DEFAULT_REGION=$REGION

echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR_BLOCK --query 'Vpc.VpcId' --output text)
echo "Created VPC with ID: $VPC_ID"

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "Enabled DNS support and hostnames for VPC."

echo "Creating Subnet..."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR_BLOCK --availability-zone $AVAILABILITY_ZONE --query 'Subnet.SubnetId' --output text)
echo "Created Subnet with ID: $SUBNET_ID"

echo "Creating Security Group..."
SG_ID=$(aws ec2 create-security-group --group-name $SG_NAME --description "Security group for EC2" --vpc-id $VPC_ID --query 'GroupId' --output text)
echo "Created Security Group with ID: $SG_ID"

aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Added inbound rules for SSH (22) and HTTP (80) to Security Group."

echo "Creating ECR repository..."
REPOSITORY_URI=$(aws ecr create-repository --repository-name $REPOSITORY_NAME --query 'repository.repositoryUri' --output text)
echo "Created ECR repository with URI: $REPOSITORY_URI"

echo "Creating EC2 Key Pair ($KEY_NAME)..."
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME
chmod 400 $KEY_NAME
echo "Created EC2 Key Pair ($KEY_NAME)."

echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "Created and attached Internet Gateway with ID: $IGW_ID."

echo "Updating Route Table to allow internet traffic..."
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text)
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Added route to the Internet Gateway in the route table."

echo "Launching EC2 Instance..."
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 instance with ID: $INSTANCE_ID"

echo "Allocating Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address --query 'AllocationId' --output text)
echo "Allocated Elastic IP with Allocation ID: $ALLOCATION_ID"

aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOCATION_ID
echo "Associated Elastic IP with EC2 instance $INSTANCE_ID."

echo "Script completed successfully!"

