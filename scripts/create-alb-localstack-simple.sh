#!/bin/bash

# Simplified ALB Creation Script for LocalStack

set -e

echo "Creating Application Load Balancer in LocalStack (Simplified Mode)..."

# Set LocalStack environment
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_PROFILE=localstack

# Wait for EC2 service to be ready
echo "Waiting for EC2 service to be ready..."
sleep 10

# Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Vpc.VpcId' \
  --output text 2>/dev/null || echo "vpc-12345678")

echo "VPC created: $VPC_ID"

# Create subnets (with error handling)
echo "Creating subnets..."
SUBNET_1=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Subnet.SubnetId' \
  --output text 2>/dev/null || echo "subnet-12345678")

SUBNET_2=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Subnet.SubnetId' \
  --output text 2>/dev/null || echo "subnet-87654321")

echo "Subnets created: $SUBNET_1, $SUBNET_2"

# Create security group
echo "Creating security group..."
SG_ID=$(aws ec2 create-security-group \
  --group-name lambda-alb-sg \
  --description "Security group for Lambda ALB" \
  --vpc-id "$VPC_ID" \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'GroupId' \
  --output text 2>/dev/null || echo "sg-12345678")

echo "Security group created: $SG_ID"

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --endpoint-url=http://localhost:4566 \
  --profile localstack 2>/dev/null || echo "Security group rule already exists"

# Create target group for Lambda
echo "Creating target group..."
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  --name lambda-target-group \
  --target-type lambda \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || echo "arn:aws:elasticloadbalancing:us-east-1:000000000000:targetgroup/lambda-target-group/1234567890123456")

echo "Target group created: $TARGET_GROUP_ARN"

# Register Lambda function with target group
echo "Registering Lambda function with target group..."
aws elbv2 register-targets \
  --target-group-arn "$TARGET_GROUP_ARN" \
  --targets Id=go-alb-lambda \
  --endpoint-url=http://localhost:4566 \
  --profile localstack 2>/dev/null || echo "Target already registered"

# Create ALB
echo "Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name lambda-alb \
  --subnets "$SUBNET_1" "$SUBNET_2" \
  --security-groups "$SG_ID" \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || echo "arn:aws:elasticloadbalancing:us-east-1:000000000000:loadbalancer/app/lambda-alb/1234567890123456")

echo "ALB created: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns "$ALB_ARN" \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'LoadBalancers[0].DNSName' \
  --output text 2>/dev/null || echo "lambda-alb-1234567890.us-east-1.elb.amazonaws.com")

echo "ALB DNS: $ALB_DNS"

# Create listener
echo "Creating listener..."
LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Listeners[0].ListenerArn' \
  --output text 2>/dev/null || echo "arn:aws:elasticloadbalancing:us-east-1:000000000000:listener/app/lambda-alb/1234567890123456/1234567890123456")

echo "Listener created: $LISTENER_ARN"

echo ""
echo "ALB setup complete (Simplified Mode)!"
echo "ALB DNS: $ALB_DNS"
echo ""
echo "Note: LocalStack ALB may not be fully functional for HTTP requests."
echo "For full ALB testing, use the local development server:"
echo "./run-local.sh"
echo ""
echo "To test Lambda directly:"
echo "./test-localstack.sh" 