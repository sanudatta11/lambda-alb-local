#!/bin/bash

# Mac-specific LocalStack startup script

set -e

# Source shared utilities
source "$(dirname "$0")/utils.sh"

print_header
print_status "Starting LocalStack with Mac-specific optimizations..."

# Check Docker resources
print_status "Checking Docker resources..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Fix Docker socket permissions (common Mac issue)
print_status "Fixing Docker socket permissions..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# Clean up any existing containers
print_status "Cleaning up existing containers..."
docker stop lambda-alb-localstack 2>/dev/null || true
docker rm lambda-alb-localstack 2>/dev/null || true

# Remove old data
print_status "Removing old LocalStack data..."
rm -rf ./localstack-data

# Start LocalStack with Mac optimizations
print_status "Starting LocalStack..."
docker-compose -f docker-compose-simple.yml up -d

# Wait for LocalStack to be ready
print_status "Waiting for LocalStack to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        print_status "LocalStack is ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "LocalStack failed to start properly."
        print_error "Check Docker Desktop resources and try again."
        exit 1
    fi
    
    print_status "Waiting for LocalStack... (attempt $attempt/$max_attempts)"
    sleep 2
    attempt=$((attempt + 1))
done

# Configure AWS CLI for LocalStack
print_status "Configuring AWS CLI for LocalStack..."
aws configure set aws_access_key_id test --profile localstack
aws configure set aws_secret_access_key test --profile localstack
aws configure set region us-east-1 --profile localstack
aws configure set output json --profile localstack

print_status "LocalStack started successfully!"

# Wait for IAM service to be ready
print_status "Waiting for IAM service to be ready..."
sleep 5

# Create IAM role for Lambda
print_status "Creating IAM role for Lambda..."
if ./scripts/create-iam-role.sh; then
    print_status "IAM role created successfully!"
else
    print_error "Failed to create IAM role. Retrying..."
    sleep 3
    ./scripts/create-iam-role.sh
fi

print_status "You can now deploy your Lambda function." 