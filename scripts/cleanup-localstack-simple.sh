#!/bin/bash

# Simple LocalStack Cleanup Script

set -e

echo "Cleaning up LocalStack (Simple Mode)..."

# Stop containers
echo "Stopping Docker containers..."
docker-compose -f docker-compose-simple.yml down 2>/dev/null || true

# Remove any dangling containers
echo "Removing dangling containers..."
docker container prune -f 2>/dev/null || true

# Clean up Docker volumes
echo "Cleaning up Docker volumes..."
docker volume prune -f 2>/dev/null || true

# Clean up Docker networks
echo "Cleaning up Docker networks..."
docker network prune -f 2>/dev/null || true

echo "LocalStack cleanup complete (Simple Mode)!"
echo ""
echo "You can now restart LocalStack with:"
echo "./start.sh  # Choose option 3: Deploy LocalStack Simple" 