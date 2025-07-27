# Mac Troubleshooting Guide

## Lambda Configuration Status Failed

If you're getting "Lambda configuration status failed" on Mac, try these solutions:

### 1. Clean Restart (Recommended)

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove LocalStack data
rm -rf ./localstack-data

# Restart LocalStack
./start.sh deploy-localstack-simple
```

### 2. Check Docker Resources

Ensure Docker has enough resources allocated:
- Open Docker Desktop
- Go to Settings → Resources
- Increase Memory to at least 4GB
- Increase CPUs to at least 2
- Restart Docker

### 3. Verify Docker Socket

```bash
# Check if Docker socket is accessible
ls -la /var/run/docker.sock

# If permission denied, fix with:
sudo chmod 666 /var/run/docker.sock
```

### 4. Alternative: Use Local Development Server

If LocalStack continues to fail, use the local development server instead:

```bash
./start.sh deploy-simple
./start.sh test-simple
```

### 5. Check LocalStack Logs

```bash
# View LocalStack logs
docker logs lambda-alb-localstack

# Follow logs in real-time
docker logs -f lambda-alb-localstack
```

### 6. Manual Lambda Creation

If automatic deployment fails, try manual creation:

```bash
# Build the function
./scripts/build.sh

# Create IAM role manually
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --endpoint-url=http://localhost:4566 \
  --profile localstack

# Attach policy
aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
  --endpoint-url=http://localhost:4566 \
  --profile localstack

# Create Lambda function
aws lambda create-function \
  --function-name go-alb-lambda \
  --runtime provided.al2 \
  --handler bootstrap \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::000000000000:role/lambda-execution-role \
  --endpoint-url=http://localhost:4566 \
  --profile localstack \
  --timeout 30 \
  --memory-size 128
```

### 7. Common Mac Issues

**Issue:** "Permission denied" on docker.sock
**Solution:** 
```bash
sudo chmod 666 /var/run/docker.sock
```

**Issue:** "No space left on device"
**Solution:**
```bash
docker system prune -a
```

**Issue:** "Connection refused" to LocalStack
**Solution:**
```bash
# Wait longer for LocalStack to start
sleep 30
# Then try deployment again
```

### 8. Fallback: Use Local Server

If LocalStack continues to have issues on Mac, the local development server provides the same functionality for testing:

```bash
# Start local server
./start.sh deploy-simple

# Test with curl
curl -X GET http://localhost:8080/
curl -X POST http://localhost:8080/ -H "Content-Type: application/json" -d '{"test": "data"}'
```

The local server simulates the Lambda function behavior without requiring LocalStack. 