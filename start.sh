#!/bin/bash

# Lambda ALB Boilerplate - Unified Starter Script

set -e

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



# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go 1.21 or later."
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install curl."
        exit 1
    fi
    
    # Check if zip is installed (needed for building Lambda packages)
    if ! command -v zip &> /dev/null; then
        print_error "Zip package is not installed."
        print_error "Please install it manually:"
        print_error "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y zip"
        print_error "  CentOS/RHEL: sudo yum install -y zip"
        print_error "  macOS: brew install zip"
        exit 1
    fi
    
    # Check Docker (for LocalStack options)
    if [[ "$1" == "localstack"* ]]; then
        if ! command -v docker &> /dev/null; then
            print_error "Docker is not installed. Please install Docker for LocalStack options."
            exit 1
        fi
        
        if ! docker info > /dev/null 2>&1; then
            print_error "Docker is not running. Please start Docker."
            exit 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            print_error "docker-compose is not installed. Please install docker-compose."
            exit 1
        fi
        
        # Check if AWS CLI is installed
        if ! command -v aws &> /dev/null; then
            print_error "AWS CLI is not installed."
            print_error "Please install it manually:"
            print_error "  Linux: https://aws.amazon.com/cli/"
            print_error "  macOS: brew install awscli"
            print_error "  Windows: https://aws.amazon.com/cli/"
            exit 1
        fi
    fi
    
    print_status "Prerequisites check completed!"
}



# Function to show help
show_help() {
    print_header
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  deploy-simple              Deploy and start local development server"
    echo "  deploy-localstack-mac      Deploy to LocalStack (Mac Optimized)"
    echo "  test-localstack-simple     Test LocalStack (Simple Mode)"
    echo "  cleanup-localstack-simple  Cleanup LocalStack (Simple Mode)"
    echo "  help                       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy-simple"
    echo "  $0 deploy-localstack-mac"
    echo "  $0 test-localstack-simple"
    echo "  $0 cleanup-localstack-simple"
    echo ""
    echo "If no option is provided, an interactive menu will be shown."
}

# Function to deploy simple (local development server)
deploy_simple() {
    print_header
    print_status "Starting local development server..."
    
    # Check prerequisites (needed for building)
    check_prerequisites
    
    # Build the Lambda binary for Mac
    print_status "Building Lambda binary for Mac..."
    ./scripts/build-mac.sh
    
    # Start the local server
    print_status "Starting local HTTP server on port 8080..."
    print_status "Server will simulate ALB requests to your Lambda function"
    print_status "Press Ctrl+C to stop the server"
    echo ""
    
    # Set environment variable and run the local server
    LOCAL_DEV=true ./bootstrap
}



# Function to test LocalStack simple
test_localstack_simple() {
    print_header
    print_status "Testing LocalStack (Simple Mode)..."
    
    # Check if LocalStack is running
    if ! curl -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        print_error "LocalStack is not running. Please deploy first with option 2."
        exit 1
    fi
    
    # Test Lambda function
    print_status "Testing Lambda function..."
    ./scripts/test-localstack.sh
}



# Function to cleanup LocalStack simple
cleanup_localstack_simple() {
    print_header
    print_status "Cleaning up LocalStack (Simple Mode)..."
    
    # Stop LocalStack containers
    print_status "Stopping LocalStack containers..."
    docker-compose -f docker-compose-simple.yml down
    
    # Clean up any remaining data
    print_status "Cleaning up LocalStack data..."
    rm -rf ./localstack-data 2>/dev/null || true
    
    print_status "LocalStack (Simple Mode) cleanup complete!"
}



# Function to deploy LocalStack Mac (optimized)
deploy_localstack_mac() {
    print_header
    print_status "Deploying LocalStack with Mac-specific optimizations..."
    
    # Check prerequisites
    check_prerequisites "localstack"
    
    # Use the Mac-specific startup script (includes IAM role creation)
    ./scripts/start-localstack-mac.sh
    
    # Wait a bit more for Lambda services to be ready
    print_status "Waiting for Lambda services to be ready..."
    sleep 10
    
    # Deploy Lambda function with Mac-specific handling
    ./scripts/deploy-lambda-localstack-mac.sh
    
    print_status "LocalStack Mac deployment complete!"
}

# Function to show interactive menu
show_menu() {
    print_header
    
    echo ""
    echo "Choose your option:"
    echo ""
    echo "1. Deploy Simple (Local Development Server)"
    echo "2. Deploy LocalStack Mac (Simple)"
    echo "3. Test LocalStack Simple"
    echo "4. Cleanup LocalStack Simple"
    echo ""
    read -p "Choose an option (1-4): " choice
    
    case $choice in
        1)
            deploy_simple
            ;;
        2)
            deploy_localstack_mac
            ;;
        3)
            test_localstack_simple
            ;;
        4)
            cleanup_localstack_simple
            ;;
        *)
            print_error "Invalid option. Please choose 1-4."
            exit 1
            ;;
    esac
}

# Main script logic
main() {
    case "${1:-}" in
        "deploy-simple")
            deploy_simple
            ;;
        "deploy-localstack-mac")
            deploy_localstack_mac
            ;;
        "test-localstack-simple")
            test_localstack_simple
            ;;
        "cleanup-localstack-simple")
            cleanup_localstack_simple
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            show_menu
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 