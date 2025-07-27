#!/bin/bash

# Deploy Lambda Function to LocalStack

set -e

# Source shared utilities
source "$(dirname "$0")/utils.sh"

print_header
print_status "Deploying Lambda function to LocalStack..."

# Set LocalStack environment
set_localstack_env

# Check if LocalStack is running
check_localstack_running

# Build Lambda function
build_lambda

# Get role ARN
ROLE_ARN=$(aws iam get-role \
  --role-name lambda-execution-role \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Role.Arn' \
  --output text)

print_status "Using role ARN: $ROLE_ARN"

# Check if function already exists
if aws lambda get-function \
  --function-name go-alb-lambda \
  --endpoint-url=http://localhost:4566 \
  --profile localstack > /dev/null 2>&1; then
    print_status "Updating existing Lambda function..."
    aws lambda update-function-code \
      --function-name go-alb-lambda \
      --zip-file fileb://function.zip \
      --endpoint-url=http://localhost:4566 \
      --profile localstack
else
    print_status "Creating new Lambda function..."
    aws lambda create-function \
      --function-name go-alb-lambda \
      --runtime provided.al2 \
      --handler bootstrap \
      --zip-file fileb://function.zip \
      --role "$ROLE_ARN" \
      --endpoint-url=http://localhost:4566 \
      --profile localstack
fi

print_status "Lambda function deployed successfully!"

# Wait for the function to be ready
wait_for_lambda_ready "go-alb-lambda" 30

# Test the function
print_status "Testing Lambda function..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{"httpMethod": "GET", "path": "/test", "headers": {}, "queryStringParameters": {}, "body": ""}' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "Function response:"
format_json response.json
rm -f response.json

print_status "Lambda deployment complete!" 