#!/bin/bash

# Create IAM Role for Lambda Execution in LocalStack

set -e

echo "Creating IAM role for Lambda execution in LocalStack..."

# Set LocalStack environment
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_PROFILE=localstack

# Create trust policy for Lambda
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create IAM role
echo "Creating IAM role..."
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document file://trust-policy.json \
  --endpoint-url=http://localhost:4566 \
  --profile localstack

# Create policy for Lambda execution
cat > lambda-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF

# Attach policy to role
echo "Attaching policy to role..."
aws iam put-role-policy \
  --role-name lambda-execution-role \
  --policy-name lambda-execution-policy \
  --policy-document file://lambda-policy.json \
  --endpoint-url=http://localhost:4566 \
  --profile localstack

# Get role ARN
ROLE_ARN=$(aws iam get-role \
  --role-name lambda-execution-role \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Role.Arn' \
  --output text)

echo "IAM role created successfully!"
echo "Role ARN: $ROLE_ARN"

# Clean up temporary files
rm -f trust-policy.json lambda-policy.json

echo "IAM role setup complete!" 