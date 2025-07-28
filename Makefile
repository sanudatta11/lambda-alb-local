# Makefile for Lambda ALB Local Development

.PHONY: help setup clean build test

# Default target
help:
	@echo "Available commands:"
	@echo "  setup     - Make all scripts executable"
	@echo "  clean     - Clean build artifacts"
	@echo "  build     - Build Lambda function for Mac"
	@echo "  test      - Test local development server"
	@echo "  help      - Show this help message"

# Make all scripts executable
setup:
	@echo "Making scripts executable..."
	chmod +x start.sh
	chmod +x scripts/*.sh
	@echo "✅ All scripts are now executable"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f bootstrap function.zip
	@echo "✅ Build artifacts cleaned"

# Build Lambda function for Mac
build:
	@echo "Building Lambda function for Mac..."
	./scripts/build-mac.sh

# Test local development server
test:
	@echo "Testing local development server..."
	./start.sh deploy-simple 