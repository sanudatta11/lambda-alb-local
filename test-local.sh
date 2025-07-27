#!/bin/bash

# Test script for local development server

BASE_URL="http://localhost:8080"

echo "Testing local Lambda ALB server..."
echo "Make sure the server is running with: ./run-local.sh"
echo ""

# Test GET request
echo "=== Testing GET request ==="
curl -X GET "$BASE_URL/" -H "Content-Type: application/json"
echo -e "\n"

# Test POST request
echo "=== Testing POST request ==="
curl -X POST "$BASE_URL/" \
  -H "Content-Type: application/json" \
  -d '{"test": "data", "message": "Hello from POST"}'
echo -e "\n"

# Test PUT request
echo "=== Testing PUT request ==="
curl -X PUT "$BASE_URL/" \
  -H "Content-Type: application/json" \
  -d '{"test": "updated", "message": "Hello from PUT"}'
echo -e "\n"

# Test DELETE request
echo "=== Testing DELETE request ==="
curl -X DELETE "$BASE_URL/"
echo -e "\n"

# Test PATCH request
echo "=== Testing PATCH request ==="
curl -X PATCH "$BASE_URL/" \
  -H "Content-Type: application/json" \
  -d '{"patch": "data", "message": "Hello from PATCH"}'
echo -e "\n"

# Test OPTIONS request (CORS)
echo "=== Testing OPTIONS request (CORS) ==="
curl -X OPTIONS "$BASE_URL/" \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"
echo -e "\n"

# Test with query parameters
echo "=== Testing GET with query parameters ==="
curl -X GET "$BASE_URL/?param1=value1&param2=value2"
echo -e "\n"

# Test unsupported method
echo "=== Testing unsupported method ==="
curl -X HEAD "$BASE_URL/"
echo -e "\n"

echo "All tests completed!" 