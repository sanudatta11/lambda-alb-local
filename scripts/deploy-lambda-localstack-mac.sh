#!/bin/bash

# Mac-specific Lambda deployment script with enhanced error handling

set -e

# Source shared utilities
source "$(dirname "$0")/utils.sh"

print_header
print_status "Deploying Lambda function to LocalStack (Mac Optimized)..."

# Set LocalStack environment
set_localstack_env

# Check if LocalStack is running
check_localstack_running

# Build Lambda function for Linux (required for container execution)
print_status "Building Lambda function for Linux (container execution)..."
./scripts/build-lambda.sh

# Verify build artifacts
print_status "Verifying build artifacts..."
if [ ! -f "bootstrap" ]; then
    print_error "Bootstrap binary not found after build"
    exit 1
fi

if [ ! -f "function.zip" ]; then
    print_error "Function.zip not found after build"
    exit 1
fi

# Check binary compatibility
print_status "Checking binary compatibility..."
file_info=$(file bootstrap 2>/dev/null || echo "Unknown")
print_status "Binary info: $file_info"

# Check file sizes
bootstrap_size=$(stat -f%z bootstrap 2>/dev/null || stat -c%s bootstrap 2>/dev/null || echo "Unknown")
zip_size=$(stat -f%z function.zip 2>/dev/null || stat -c%s function.zip 2>/dev/null || echo "Unknown")
print_status "Bootstrap size: ${bootstrap_size} bytes"
print_status "Function.zip size: ${zip_size} bytes"

# Get role ARN
print_status "Getting IAM role ARN..."
ROLE_ARN=$(aws iam get-role \
  --role-name lambda-execution-role \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --query 'Role.Arn' \
  --output text 2>/dev/null || echo "")

if [ -z "$ROLE_ARN" ]; then
    print_error "IAM role not found. Creating it now..."
    ./scripts/create-iam-role.sh
    ROLE_ARN=$(aws iam get-role \
      --role-name lambda-execution-role \
      --endpoint-url=http://localhost:4566 \
      --profile localstack \
      --query 'Role.Arn' \
      --output text)
fi

print_status "Using role ARN: $ROLE_ARN"

# Check if function already exists
if aws lambda get-function \
  --function-name go-alb-lambda \
  --endpoint-url=http://localhost:4566 \
  --profile localstack > /dev/null 2>&1; then
    print_status "Updating existing Lambda function..."
    if ! aws lambda update-function-code \
      --function-name go-alb-lambda \
      --zip-file fileb://function.zip \
      --endpoint-url=http://localhost:4566 \
      --profile localstack; then
        print_error "Failed to update Lambda function"
        exit 1
    fi
else
    print_status "Creating new Lambda function..."
    if ! aws lambda create-function \
      --function-name go-alb-lambda \
      --runtime provided.al2 \
      --handler bootstrap \
      --zip-file fileb://function.zip \
      --role "$ROLE_ARN" \
      --endpoint-url=http://localhost:4566 \
      --profile localstack \
      --timeout 30 \
      --memory-size 128; then
        print_error "Failed to create Lambda function"
        exit 1
    fi
fi

print_status "Lambda function deployed successfully!"

# Wait for the function to be ready
print_status "Waiting for Lambda function to be ready..."
if ! wait_for_lambda_ready "go-alb-lambda" 15; then
    print_error "Lambda function failed to start"
    exit 1
fi

# Test the function if it's available
print_status "Testing Lambda function..."
if aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{"httpMethod": "GET", "path": "/test", "headers": {}, "queryStringParameters": {}, "body": ""}' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json 2>/dev/null; then
    print_status "Function response:"
    format_json response.json
    rm -f response.json
    print_status "Lambda deployment and test successful!"
else
    print_warning "Function test failed, but deployment completed."
    print_warning "This is common on Mac. Try the local development server instead:"
    print_warning "  ./start.sh deploy-simple"
fi 