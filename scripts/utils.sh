#!/bin/bash

# Shared utility functions for Lambda ALB scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Lambda ALB Boilerplate${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Function to set LocalStack environment
set_localstack_env() {
    export AWS_ENDPOINT_URL=http://localhost:4566
    export AWS_PROFILE=localstack
}

# Function to wait for Lambda function to be ready
wait_for_lambda_ready() {
    local function_name=${1:-"go-alb-lambda"}
    local max_attempts=${2:-15}
    local attempt=1
    
    print_status "Checking if Lambda function is ready..."
    
    while [ $attempt -le $max_attempts ]; do
        # Try to get function state and details
        function_info=$(aws lambda get-function \
          --function-name "$function_name" \
          --endpoint-url=http://localhost:4566 \
          --profile localstack 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            function_state=$(echo "$function_info" | jq -r '.Configuration.State // "Unknown"')
        
        if [ "$function_state" = "Active" ]; then
            print_status "Lambda function is ready!"
            return 0
        elif [ "$function_state" = "Failed" ]; then
                print_error "Lambda function is in failed state"
                
                # Get detailed error information
                print_error "=== Lambda Function Details ==="
                echo "$function_info" | jq -r '.Configuration | {State, LastUpdateStatus, LastUpdateStatusReason, LastUpdateStatusReasonCode}' 2>/dev/null || echo "Could not parse function details"
                
                # Check for container logs if available
                print_error "=== Container Logs (if available) ==="
                docker logs lambda-alb-localstack 2>&1 | tail -20 || echo "Could not retrieve container logs"
                
            return 1
            fi
        else
            print_warning "Could not retrieve function state (attempt $attempt/$max_attempts)"
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Function may not be fully ready, but continuing..."
            return 0
        fi
        
        print_status "Function not ready yet (state: $function_state), waiting 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done
}

# Function to format JSON output
format_json() {
    local file="$1"
    if command -v jq &> /dev/null; then
        cat "$file" | jq .
    else
        cat "$file" | python3 -m json.tool
    fi
}

# Function to check if LocalStack is running
check_localstack_running() {
    if ! curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        print_error "LocalStack is not running. Please start it first with: ./start.sh simple-localstack"
        exit 1
    fi
}

# Function to build Lambda function
build_lambda() {
    if [ ! -f "function.zip" ]; then
        print_status "Building Lambda function..."
        ./scripts/build.sh
    fi
} 