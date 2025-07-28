#!/bin/bash

# Mac-specific Go Lambda Build Script (for local development server)

set -e

echo "Building Go Lambda function for Mac (local development server)..."

# Clean up previous builds
rm -f bootstrap function.zip

# Download dependencies
echo "Downloading dependencies..."
go mod tidy

# Detect Mac architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    GOARCH=amd64
elif [ "$ARCH" = "arm64" ]; then
    GOARCH=arm64
else
    echo "Unknown architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH ($GOARCH)"

# Build for local architecture (Mac)
echo "Building binary for Mac ($GOARCH)..."
GOOS=darwin GOARCH=$GOARCH go build -o bootstrap main.go

# Create deployment package
echo "Creating deployment package..."
zip function.zip bootstrap

echo "Build complete!"
echo "Files created:"
echo "  - bootstrap (executable for Mac)"
echo "  - function.zip (deployment package)"

# Optional: Show file sizes
echo ""
echo "File sizes:"
ls -lh bootstrap function.zip

echo ""
echo "Note: This build is for local development server on Mac."
echo "For LocalStack deployment, the script will build for Linux automatically." 