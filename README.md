# Go Lambda ALB Boilerplate - Local Development

This is a boilerplate Go Lambda function that handles different HTTP request types and returns JSON responses. It's designed to work with AWS Application Load Balancer (ALB) and includes local development capabilities.

## Features

- Handles all major HTTP methods: GET, POST, PUT, DELETE, PATCH
- Returns JSON responses with request details
- CORS support for web applications
- Proper error handling and logging
- ALB integration ready
- **Local development server** for testing

## Project Structure

```
.
├── main.go           # Main Lambda function with local server support
├── go.mod            # Go module dependencies
├── build.sh          # Build script for Lambda deployment
├── run-local.sh      # Script to start local development server
├── test-local.sh     # Script to test all HTTP methods locally
└── README.md         # This file
```

## Local Development

### Prerequisites

- Go 1.21 or later
- curl (for testing)

### Quick Start

1. **Start the local server:**
   ```bash
   ./run-local.sh
   ```
   
   Or manually:
   ```bash
   LOCAL_DEV=true go run main.go
   ```

2. **Test the server:**
   ```bash
   ./test-local.sh
   ```

3. **Manual testing with curl:**
   ```bash
   # GET request
   curl -X GET http://localhost:8080/
   
   # POST request
   curl -X POST http://localhost:8080/ \
     -H "Content-Type: application/json" \
     -d '{"key": "value"}'
   
   # PUT request
   curl -X PUT http://localhost:8080/ \
     -H "Content-Type: application/json" \
     -d '{"key": "updated_value"}'
   
   # DELETE request
   curl -X DELETE http://localhost:8080/
   
   # PATCH request
   curl -X PATCH http://localhost:8080/ \
     -H "Content-Type: application/json" \
     -d '{"key": "patched_value"}'
   ```

### Environment Variables

- `LOCAL_DEV=true` - Enables local development mode
- `PORT=8080` - Sets the port for local server (default: 8080)

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

## Development Workflow

1. **Local Development:**
   - Use `./run-local.sh` to start the local server
   - Use `./test-local.sh` to test all endpoints
   - Make changes to `main.go` and restart the server

2. **Testing:**
   - All HTTP methods are tested automatically
   - Check response format and status codes
   - Verify CORS headers

3. **Deployment:**
   - Use `./build.sh` to create deployment package
   - Deploy to AWS Lambda
   - Attach to Application Load Balancer

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

### Logs

The local server provides detailed logging:
- Request details (method, path)
- Response details
- Error information

Check the terminal output for debugging information. 