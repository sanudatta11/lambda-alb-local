#!/bin/bash

# Local Development Server Script

echo "Starting local development server..."
echo "Set LOCAL_DEV=true to run in local mode"

# Set environment variable for local development
export LOCAL_DEV=true

# Set port (optional, defaults to 8080)
export PORT=${PORT:-8080}

echo "Server will start on port $PORT"
echo "Press Ctrl+C to stop the server"
echo ""

# Run the Go application
go run main.go 