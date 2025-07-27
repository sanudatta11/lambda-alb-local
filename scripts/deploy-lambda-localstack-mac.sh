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

# Build Lambda function for Mac
print_status "Building Lambda function for Mac..."
./scripts/build-mac.sh

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
    aws lambda update-function-code \
      --function-name go-alb-lambda \
      --zip-file fileb://function.zip \
      --endpoint-url=http://localhost:4566 \
      --profile localstack
else
    print_status "Creating new Lambda function..."
    aws lambda create-function \
      --function-name go-alb-lambda \
      --runtime provided.al2023 \
      --handler bootstrap \
      --zip-file fileb://function.zip \
      --role "$ROLE_ARN" \
      --endpoint-url=http://localhost:4566 \
      --profile localstack \
      --timeout 30 \
      --memory-size 128
fi

print_status "Lambda function deployed successfully!"

# Wait for the function to be ready with Mac-specific handling
print_status "Waiting for Lambda function to be ready (Mac optimized)..."
max_attempts=20
attempt=1

while [ $attempt -le $max_attempts ]; do
    # Try to get function state
    function_state=$(aws lambda get-function \
      --function-name go-alb-lambda \
      --endpoint-url=http://localhost:4566 \
      --profile localstack \
      --query 'Configuration.State' \
      --output text 2>/dev/null || echo "Unknown")
    
    if [ "$function_state" = "Active" ]; then
        print_status "Lambda function is ready!"
        break
    elif [ "$function_state" = "Failed" ]; then
        print_warning "Lambda function shows failed state (attempt $attempt/$max_attempts)"
        
        if [ $attempt -lt 5 ]; then
            # Try to update the function to trigger a restart
            print_status "Attempting to recover by updating function..."
            if aws lambda update-function-code \
              --function-name go-alb-lambda \
              --zip-file fileb://function.zip \
              --endpoint-url=http://localhost:4566 \
              --profile localstack > /dev/null 2>&1; then
                print_status "Function updated, waiting for restart..."
                sleep 10
            fi
        else
            print_error "Lambda function failed to start after multiple attempts."
            print_error "This is a known issue with LocalStack on Mac."
            print_error ""
            print_error "Recommendations:"
            print_error "1. Try the local development server: ./start.sh deploy-simple"
            print_error "2. Check Docker Desktop resources (increase memory to 4GB+)"
            print_error "3. Restart Docker Desktop and try again"
            print_error ""
            print_warning "Continuing anyway - function may work despite the error..."
            break
        fi
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_warning "Function may not be fully ready, but continuing..."
        break
    fi
    
    print_status "Function not ready yet (state: $function_state), waiting 5 seconds..."
    sleep 5
    attempt=$((attempt + 1))
done

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