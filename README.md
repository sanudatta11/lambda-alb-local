# Go Lambda ALB Boilerplate - Local Development

This is a boilerplate Go Lambda function that handles different HTTP request types and returns JSON responses. It's designed to work with AWS Application Load Balancer (ALB) and includes multiple local development options.

## Features

- Handles all major HTTP methods: GET, POST, PUT, DELETE, PATCH
- Returns JSON responses with request details
- CORS support for web applications
- Proper error handling and logging
- ALB integration ready
- **Local development server** for testing
- **LocalStack integration** for full AWS service simulation

## Project Structure

```
.
├── main.go                    # Main Lambda function with local server support
├── go.mod                     # Go module dependencies
├── go.sum                     # Go module checksums
├── start.sh                   # Unified starter script (main entry point)
├── docker-compose.yml         # LocalStack Docker Compose configuration (Advanced)
├── docker-compose-simple.yml  # LocalStack Docker Compose configuration (Simple)
├── scripts/                   # All utility scripts
│   ├── utils.sh               # Shared utility functions
│   ├── build.sh               # Build script for Lambda deployment
│   ├── create-iam-role.sh     # Create IAM role for LocalStack
│   ├── deploy-lambda-localstack.sh # Deploy Lambda to LocalStack
│   ├── test-localstack.sh     # Test Lambda in LocalStack
│   ├── create-alb-localstack-simple.sh # Create ALB in LocalStack
│   ├── cleanup-localstack-simple.sh # Cleanup LocalStack (Simple Mode)
│   └── install-prerequisites.sh # Prerequisites checker script
├── .gitignore                 # Git ignore file
└── README.md                  # This file
```

## Local Development

### Prerequisites

- Go 1.21 or later
- curl (for testing)
- Docker and docker-compose (for LocalStack)
- AWS CLI (for LocalStack testing)
- zip (for building Lambda deployment packages)

**Prerequisites Check:**
The project includes automatic checking of prerequisites. When you run any LocalStack option, the script will:
- Check if AWS CLI is installed and provide installation instructions if missing
- Check if zip package is installed and provide installation instructions if missing
- Exit with clear error messages if prerequisites are not met

**Manual Installation:**
You must install prerequisites manually:
```bash
# Install AWS CLI
# Linux:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# macOS:
brew install awscli

# Install zip package
# Ubuntu/Debian:
sudo apt-get update && sudo apt-get install -y zip

# CentOS/RHEL:
sudo yum install -y zip

# macOS:
brew install zip
```

**Prerequisites Checker:**
```bash
./scripts/install-prerequisites.sh
```

### Quick Start

**Single Entry Point - Unified Starter Script**

```bash
./start.sh
```

This will show an interactive menu with 8 options:

1. **Deploy Simple** - Start local development server
2. **Test Simple** - Test local development server
3. **Deploy LocalStack Simple** - Deploy to LocalStack (Simple Mode)
4. **Test LocalStack Simple** - Test LocalStack (Simple Mode)
5. **Cleanup LocalStack Simple** - Cleanup LocalStack (Simple Mode)
6. **Deploy LocalStack Advanced** - Deploy to LocalStack (Advanced Mode)
7. **Test LocalStack Advanced** - Test LocalStack (Advanced Mode)
8. **Cleanup LocalStack Advanced** - Cleanup LocalStack (Advanced Mode)

Or you can specify directly:

```bash
# Local development server
./start.sh deploy-simple
./start.sh test-simple

# LocalStack (Simple Mode) - RECOMMENDED
./start.sh deploy-localstack-simple
./start.sh test-localstack-simple
./start.sh cleanup-localstack-simple

# LocalStack (Advanced Mode)
./start.sh deploy-localstack-advanced
./start.sh test-localstack-advanced
./start.sh cleanup-localstack-advanced

# Show help
./start.sh help
```

#### Option 1: Local Development Server

The starter script will automatically:
- Check prerequisites
- Build the Lambda binary
- Start the local server on port 8080
- Provide testing instructions

#### Option 2: Test Local Development Server

Tests all HTTP methods against the running local server:
- GET, POST, PUT, DELETE, PATCH, OPTIONS
- Validates JSON responses
- Checks status codes

#### Option 3: Deploy LocalStack Simple

The starter script will automatically:
- Check prerequisites (Docker, AWS CLI)
- Install AWS CLI if needed
- Start LocalStack (Simple Mode)
- Configure AWS CLI for LocalStack
- Build and deploy Lambda function
- Create IAM role

#### Option 4: Test LocalStack Simple

Tests the deployed Lambda function in LocalStack:
- Direct Lambda invocation
- All HTTP methods
- JSON response validation

#### Option 5: Cleanup LocalStack Simple

Cleans up LocalStack (Simple Mode):
- Stops containers
- Removes data directories

#### Option 6: Deploy LocalStack Advanced

The starter script will automatically:
- Check prerequisites (Docker, AWS CLI)
- Install AWS CLI if needed
- Start LocalStack (Advanced Mode)
- Configure AWS CLI for LocalStack
- Build and deploy Lambda function
- Create IAM role

#### Option 7: Test LocalStack Advanced

Tests the deployed Lambda function in LocalStack:
- Direct Lambda invocation
- All HTTP methods
- JSON response validation

#### Option 8: Cleanup LocalStack Advanced

Cleans up LocalStack (Advanced Mode):
- Stops containers and removes volumes
- Removes data directories

### Environment Variables

- `LOCAL_DEV=true` - Enables local development mode
- `PORT=8080` - Sets the port for local server (default: 8080)
- `AWS_ENDPOINT_URL=http://localhost:4566` - LocalStack endpoint
- `AWS_PROFILE=localstack` - LocalStack AWS profile

## Response Format

The function returns JSON responses with the following structure:

```json
{
  "message": "GET request processed successfully",
  "request_type": "GET",
  "path": "/",
  "method": "GET",
  "headers": {
    "Content-Type": "application/json",
    "User-Agent": "curl/7.68.0"
  },
  "query_params": {
    "param1": "value1"
  },
  "body": "",
  "status": 200
}
```

## HTTP Methods Supported

| Method | Status Code | Description |
|--------|-------------|-------------|
| GET    | 200         | Retrieve data |
| POST   | 201         | Create new resource |
| PUT    | 200         | Update resource |
| DELETE | 200         | Delete resource |
| PATCH  | 200         | Partial update |
| OPTIONS| 200         | CORS preflight |

## Error Handling

The function includes proper error handling for:
- Unsupported HTTP methods (405 Method Not Allowed)
- Internal server errors (500 Internal Server Error)
- JSON marshaling errors

## CORS Support

The function includes CORS headers to support web applications:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`

## Building for Lambda Deployment

When you're ready to deploy to AWS Lambda:

1. **Build the Lambda function:**
   ```bash
   ./build.sh
   ```

2. **Deploy to AWS Lambda:**
   ```bash
   aws lambda create-function \
     --function-name go-alb-lambda \
     --runtime provided.al2 \
     --handler bootstrap \
     --zip-file fileb://function.zip \
     --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role
   ```

## LocalStack Simple vs Advanced Mode

| Feature | LocalStack Simple | LocalStack Advanced |
|---------|-------------------|---------------------|
| **Setup Complexity** | Simple | Moderate |
| **Data Persistence** | No (stateless) | Yes (volumes) |
| **Debug Logging** | Minimal | Full debug output |
| **Resource Usage** | Low | High |
| **Startup Time** | Fast (~10 seconds) | Slow (~15 seconds) |
| **Reliability** | High (no persistence issues) | Medium (persistence can cause issues) |
| **Use Case** | Quick testing, CI/CD | Development with data persistence |
| **Cleanup** | Simple container stop | Full cleanup with volume removal |

## LocalStack vs Local Server

| Feature | Local Server | LocalStack Simple | LocalStack Advanced |
|---------|-------------|-------------------|---------------------|
| **Setup Complexity** | Simple | Simple | Moderate |
| **AWS Service Simulation** | None | Full | Full |
| **Lambda Testing** | HTTP simulation | Real Lambda | Real Lambda |
| **ALB Testing** | HTTP simulation | Real ALB | Real ALB |
| **IAM/Roles** | Not needed | Full simulation | Full simulation |
| **Resource Usage** | Low | Medium (Docker) | High (Docker + volumes) |
| **Startup Time** | Fast | Medium | Slow |
| **Data Persistence** | None | None | Yes |

**Recommendation:**
- Use **Local Server** for quick development and testing
- Use **LocalStack Simple** for integration testing and AWS service validation (RECOMMENDED)
- Use **LocalStack Advanced** for development requiring data persistence

## Development Workflow

### Quick Development Cycle
1. **Start Local Development:**
   ```bash
   ./start.sh  # Choose option 1: Deploy Simple
   ```

2. **Test Local Development:**
   ```bash
   ./start.sh  # Choose option 2: Test Simple
   ```

3. **Make Changes:**
   - Edit `main.go`
   - Restart the local server (Ctrl+C, then option 1 again)

### LocalStack Testing Cycle
1. **Deploy to LocalStack Simple (Recommended):**
   ```bash
   ./start.sh  # Choose option 3: Deploy LocalStack Simple
   ```

2. **Test LocalStack:**
   ```bash
   ./start.sh  # Choose option 4: Test LocalStack Simple
   ```

3. **Cleanup when done:**
   ```bash
   ./start.sh  # Choose option 5: Cleanup LocalStack Simple
   ```

### Advanced LocalStack Testing
1. **Deploy to LocalStack Advanced:**
   ```bash
   ./start.sh  # Choose option 6: Deploy LocalStack Advanced
   ```

2. **Test LocalStack Advanced:**
   ```bash
   ./start.sh  # Choose option 7: Test LocalStack Advanced
   ```

3. **Cleanup when done:**
   ```bash
   ./start.sh  # Choose option 8: Cleanup LocalStack Advanced
   ```

### Testing Details
- All HTTP methods are tested automatically (GET, POST, PUT, DELETE, PATCH, OPTIONS)
- Check response format and status codes
- Verify CORS headers
- JSON response validation

### Production Deployment
1. **Build for AWS:**
   ```bash
   ./scripts/build.sh
   ```

2. **Deploy to AWS Lambda:**
   ```bash
   aws lambda create-function \
     --function-name go-alb-lambda \
     --runtime provided.al2 \
     --handler bootstrap \
     --zip-file fileb://function.zip \
     --role arn:aws:iam::YOUR_ACCOUNT_ID:role/lambda-execution-role
   ```

3. **Attach to Application Load Balancer**

## Customization

To customize this boilerplate:

1. **Add route-specific logic**: Modify the switch statement in `handleRequest`
2. **Add authentication**: Implement middleware for JWT or API key validation
3. **Add database integration**: Include database connections and queries
4. **Add environment variables**: Use `os.Getenv()` to read configuration
5. **Add structured logging**: Replace `log.Printf` with a structured logging library

## Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   export PORT=8081
   ./run-local.sh
   ```

2. **Dependencies not found:**
   ```bash
   go mod tidy
   ```

3. **Permission denied:**
   ```bash
   chmod +x *.sh
   ```

4. **LocalStack not starting:**
   ```bash
   # Try simple mode first (recommended)
   ./start.sh  # Choose option 5: Cleanup LocalStack Simple
   ./start.sh  # Choose option 3: Deploy LocalStack Simple
   
   # If that doesn't work, try advanced mode
   ./start.sh  # Choose option 8: Cleanup LocalStack Advanced
   ./start.sh  # Choose option 6: Deploy LocalStack Advanced
   ```

5. **AWS CLI not configured for LocalStack:**
   ```bash
   aws configure set aws_access_key_id test --profile localstack
   aws configure set aws_secret_access_key test --profile localstack
   aws configure set region us-east-1 --profile localstack
   ```

### Logs

The local server provides detailed logging:
- Request details (method, path)
- Response details
- Error information

Check the terminal output for debugging information. 