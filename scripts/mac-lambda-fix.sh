#!/bin/bash

# Comprehensive Mac Lambda fix script

set -e

# Source shared utilities
source "$(dirname "$0")/utils.sh"

print_header
print_status "Running comprehensive Mac Lambda fix..."

# 1. Check Docker resources
print_status "1. Checking Docker resources..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi

# 2. Fix Docker socket permissions
print_status "2. Fixing Docker socket permissions..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

# 3. Clean up Docker resources
print_status "3. Cleaning up Docker resources..."
docker system prune -f > /dev/null 2>&1 || true

# 4. Stop and remove existing containers
print_status "4. Stopping existing containers..."
docker stop lambda-alb-localstack 2>/dev/null || true
docker rm lambda-alb-localstack 2>/dev/null || true

# 5. Remove old data
print_status "5. Removing old LocalStack data..."
rm -rf ./localstack-data

# 6. Check Docker Desktop resources
print_status "6. Checking Docker Desktop resources..."
print_warning "Please ensure Docker Desktop has:"
print_warning "  - Memory: At least 4GB allocated"
print_warning "  - CPUs: At least 2 allocated"
print_warning "  - Disk: At least 10GB free space"

# 7. Start LocalStack with Mac optimizations
print_status "7. Starting LocalStack with Mac optimizations..."
docker-compose -f docker-compose-simple.yml up -d

# 8. Wait for LocalStack to be ready
print_status "8. Waiting for LocalStack to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        print_status "LocalStack is ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "LocalStack failed to start properly."
        print_error "Please check Docker Desktop resources and try again."
        exit 1
    fi
    
    print_status "Waiting for LocalStack... (attempt $attempt/$max_attempts)"
    sleep 2
    attempt=$((attempt + 1))
done

# 9. Configure AWS CLI
print_status "9. Configuring AWS CLI..."
aws configure set aws_access_key_id test --profile localstack
aws configure set aws_secret_access_key test --profile localstack
aws configure set region us-east-1 --profile localstack
aws configure set output json --profile localstack

# 10. Wait for services to be ready
print_status "10. Waiting for services to be ready..."
sleep 15

# 11. Create IAM role
print_status "11. Creating IAM role..."
./scripts/create-iam-role.sh

# 12. Deploy Lambda with Mac-specific handling
print_status "12. Deploying Lambda function..."
./scripts/deploy-lambda-localstack-mac.sh

print_status "Mac Lambda fix complete!"
print_status "If Lambda still fails, use the local development server:"
print_status "  ./start.sh deploy-simple" 