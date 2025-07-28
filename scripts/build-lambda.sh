#!/bin/bash

# Build script for Lambda deployment
# Always builds for Linux as Lambda runs in containers

set -e

echo "Building Go Lambda function for LocalStack deployment..."

# Clean up previous builds
rm -f bootstrap function.zip

# Download dependencies
echo "Downloading dependencies..."
go mod tidy

# Build for Linux (required for Lambda containers)
echo "Building binary for Linux (amd64)..."
GOOS=linux GOARCH=amd64 go build -o bootstrap main.go

# Create deployment package
echo "Creating deployment package..."
zip function.zip bootstrap

echo "Build complete!"
echo "Files created:"
echo "  - bootstrap (Linux executable for Lambda container)"
echo "  - function.zip (Lambda deployment package)"

# Optional: Show file sizes
echo ""
echo "File sizes:"
ls -lh bootstrap function.zip

echo ""
echo "Note: Built for Linux/amd64 as Lambda runs in Linux containers." 