#!/bin/bash

# Prerequisites Checker Script for Go Lambda ALB Boilerplate
# This script checks if AWS CLI and zip package are installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo "========================================"
    echo "  Go Lambda ALB Prerequisites Checker"
    echo "========================================"
    echo ""
}



# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Main check function
main() {
    print_header
    
    print_status "Checking prerequisites..."
    
    all_installed=true
    
    # Check AWS CLI
    if command_exists aws; then
        print_success "AWS CLI is already installed: $(aws --version)"
    else
        print_error "AWS CLI is not installed."
        print_error "Please install it manually:"
        print_error "  Linux: https://aws.amazon.com/cli/"
        print_error "  macOS: brew install awscli"
        print_error "  Windows: https://aws.amazon.com/cli/"
        all_installed=false
    fi
    
    # Check zip
    if command_exists zip; then
        print_success "Zip package is already installed: $(zip --version | head -n1)"
    else
        print_error "Zip package is not installed."
        print_error "Please install it manually:"
        print_error "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y zip"
        print_error "  CentOS/RHEL: sudo yum install -y zip"
        print_error "  macOS: brew install zip"
        all_installed=false
    fi
    
    echo ""
    if [ "$all_installed" = true ]; then
        print_success "All prerequisites are installed!"
        print_status "You can now run: ./start.sh"
    else
        print_error "Some prerequisites are missing. Please install them and try again."
        exit 1
    fi
}

# Run main function
main "$@" 