#!/bin/bash

# Test Mac build script

set -e

echo "Testing Mac build..."

# Build for Mac
./scripts/build-mac.sh

# Test the binary locally
echo "Testing binary locally..."
if ./bootstrap; then
    echo "✅ Binary runs successfully on Mac"
else
    echo "❌ Binary failed to run on Mac"
    exit 1
fi

echo "✅ Mac build test passed!" 