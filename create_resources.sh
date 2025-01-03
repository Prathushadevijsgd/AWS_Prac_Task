**Write one or several bash scripts (using AWS CLI) which:**
**Create VPC, Subnet, Elastic Container Registry (ECR), EC2 instance, Public IP Address for EC2 instance, Security Groups**

#!/bin/bash

# Set variables
VPC_CIDR_BLOCK="10.0.0.0/16"
SUBNET_CIDR_BLOCK="10.0.1.0/24"
AVAILABILITY_ZONE="us-east-1a"  
AMI_ID="ami-02dcfe5d1d39baa4e"  
INSTANCE_TYPE="t4g.nano"
KEY_NAME="newkp.pem"  
REGION="us-east-1"  
SG_NAME="MySecurityGroupcli"
REPOSITORY_NAME="my-repository"

# Set AWS Region
export AWS_DEFAULT_REGION=$REGION

# 1. Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR_BLOCK --query 'Vpc.VpcId' --output text)
echo "Created VPC with ID: $VPC_ID"

# Enable DNS Support and DNS Hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "Enabled DNS support and hostnames for VPC."

# 2. Create Subnet
echo "Creating Subnet..."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR_BLOCK --availability-zone $AVAILABILITY_ZONE --query 'Subnet.SubnetId' --output text)
echo "Created Subnet with ID: $SUBNET_ID"

# 3. Create Security Group
echo "Creating Security Group..."
SG_ID=$(aws ec2 create-security-group --group-name $SG_NAME --description "Security group for EC2" --vpc-id $VPC_ID --query 'GroupId' --output text)
echo "Created Security Group with ID: $SG_ID"

# Allow SSH and HTTP traffic
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 9090 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0
echo "Added inbound rules for SSH (22) and HTTP (80) to Security Group."

# 4. Create Elastic Container Registry (ECR)
echo "Creating ECR repository..."
REPOSITORY_URI=$(aws ecr create-repository --repository-name $REPOSITORY_NAME --query 'repository.repositoryUri' --output text)
echo "Created ECR repository with URI: $REPOSITORY_URI"

# 5. Create EC2 Key Pair (`kpcli.pem`)
echo "Creating EC2 Key Pair ($KEY_NAME)..."
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_NAME
chmod 400 $KEY_NAME
echo "Created EC2 Key Pair ($KEY_NAME)."

# 6. Create and Attach an Internet Gateway to the VPC
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
echo "Created and attached Internet Gateway with ID: $IGW_ID."

# 7. Update the Route Table to Allow Traffic to the Internet
echo "Updating Route Table to allow internet traffic..."
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[0].RouteTableId' --output text)
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Added route to the Internet Gateway in the route table."

# 8. Launch EC2 Instance
echo "Launching EC2 Instance..."
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 instance with ID: $INSTANCE_ID"

# 9. Allocate and Associate Public IP for EC2 Instance
echo "Allocating Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address --query 'AllocationId' --output text)
echo "Allocated Elastic IP with Allocation ID: $ALLOCATION_ID"

# Associate the Elastic IP with the EC2 instance
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $ALLOCATION_ID
echo "Associated Elastic IP with EC2 instance $INSTANCE_ID."

echo "Script completed successfully!"

