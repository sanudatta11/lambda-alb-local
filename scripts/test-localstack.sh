#!/bin/bash

# Test Lambda Function in LocalStack

set -e

# Source shared utilities
source "$(dirname "$0")/utils.sh"

print_header
print_status "Testing Lambda function in LocalStack..."

# Set LocalStack environment
set_localstack_env

# Check if LocalStack is running
check_localstack_running

# Wait for the function to be ready
wait_for_lambda_ready

# Test direct Lambda invocation
print_status "=== Testing direct Lambda invocation ==="

# Test GET request
print_status "Testing GET request..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{
    "httpMethod": "GET",
    "path": "/test",
    "headers": {"Content-Type": "application/json"},
    "queryStringParameters": {"param1": "value1"},
    "body": ""
  }' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "GET response:"
format_json response.json

# Test POST request
echo ""
print_status "Testing POST request..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{
    "httpMethod": "POST",
    "path": "/test",
    "headers": {"Content-Type": "application/json"},
    "queryStringParameters": {},
    "body": "{\"test\": \"data\", \"message\": \"Hello from POST\"}"
  }' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "POST response:"
format_json response.json

# Test PUT request
echo ""
print_status "Testing PUT request..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{
    "httpMethod": "PUT",
    "path": "/test",
    "headers": {"Content-Type": "application/json"},
    "queryStringParameters": {},
    "body": "{\"test\": \"updated\", \"message\": \"Hello from PUT\"}"
  }' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "PUT response:"
format_json response.json

# Test DELETE request
echo ""
print_status "Testing DELETE request..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{
    "httpMethod": "DELETE",
    "path": "/test",
    "headers": {},
    "queryStringParameters": {},
    "body": ""
  }' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "DELETE response:"
format_json response.json

# Test PATCH request
echo ""
print_status "Testing PATCH request..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{
    "httpMethod": "PATCH",
    "path": "/test",
    "headers": {"Content-Type": "application/json"},
    "queryStringParameters": {},
    "body": "{\"patch\": \"data\", \"message\": \"Hello from PATCH\"}"
  }' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "PATCH response:"
format_json response.json

# Test OPTIONS request
echo ""
print_status "Testing OPTIONS request..."
aws lambda invoke \
  --function-name go-alb-lambda \
  --payload '{
    "httpMethod": "OPTIONS",
    "path": "/test",
    "headers": {"Origin": "http://localhost:3000"},
    "queryStringParameters": {},
    "body": ""
  }' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  response.json

print_status "OPTIONS response:"
format_json response.json

# Clean up
rm -f response.json

print_status "All LocalStack tests completed!"
echo ""
print_status "To test with ALB (if created):"
echo "curl -X GET http://<ALB-DNS>/"
echo ""
print_status "To view Lambda logs:"
echo "aws logs describe-log-groups --endpoint-url=http://localhost:4566 --profile localstack" 