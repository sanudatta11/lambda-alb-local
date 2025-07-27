#!/bin/bash

# Go Lambda ALB Boilerplate Build Script

set -e

echo "Building Go Lambda function..."

# Clean up previous builds
rm -f bootstrap function.zip

# Download dependencies
echo "Downloading dependencies..."
go mod tidy

# Build for Linux (required for AWS Lambda)
echo "Building binary for Linux..."
GOOS=linux GOARCH=amd64 go build -o bootstrap main.go

# Create deployment package
echo "Creating deployment package..."
zip function.zip bootstrap

echo "Build complete!"
echo "Files created:"
echo "  - bootstrap (executable)"
echo "  - function.zip (deployment package)"

# Optional: Show file sizes
echo ""
echo "File sizes:"
ls -lh bootstrap function.zip 