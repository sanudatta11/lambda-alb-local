package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// Response represents the JSON response structure
type Response struct {
	Message     string            `json:"message"`
	RequestType string            `json:"request_type"`
	Path        string            `json:"path"`
	Method      string            `json:"method"`
	Headers     map[string]string `json:"headers,omitempty"`
	QueryParams map[string]string `json:"query_params,omitempty"`
	Body        string            `json:"body,omitempty"`
	Status      int               `json:"status"`
}

// ErrorResponse represents error JSON response structure
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Status  int    `json:"status"`
}

// handleRequest processes the ALB request and returns appropriate response
func handleRequest(ctx context.Context, request events.ALBTargetGroupRequest) (events.ALBTargetGroupResponse, error) {
	log.Printf("Received request: %s %s", request.HTTPMethod, request.Path)

	// Create response headers
	headers := map[string]string{
		"Content-Type":                 "application/json",
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type, Authorization",
	}

	// Handle OPTIONS request for CORS
	if request.HTTPMethod == http.MethodOptions {
		corsResponse := Response{
			Message:     "CORS preflight request handled successfully",
			RequestType: "OPTIONS",
			Path:        request.Path,
			Method:      request.HTTPMethod,
			Headers:     request.Headers,
			Status:      http.StatusOK,
		}

		corsBody, _ := json.Marshal(corsResponse)
		return events.ALBTargetGroupResponse{
			StatusCode: http.StatusOK,
			Headers:    headers,
			Body:       string(corsBody),
		}, nil
	}

	// Create base response
	response := Response{
		Message:     fmt.Sprintf("Successfully processed %s request", request.HTTPMethod),
		RequestType: request.HTTPMethod,
		Path:        request.Path,
		Method:      request.HTTPMethod,
		Headers:     request.Headers,
		QueryParams: request.QueryStringParameters,
		Body:        request.Body,
		Status:      http.StatusOK,
	}

	// Handle different HTTP methods
	switch request.HTTPMethod {
	case http.MethodGet:
		response.Message = "GET request processed successfully"
		response.Status = http.StatusOK

	case http.MethodPost:
		response.Message = "POST request processed successfully"
		response.Status = http.StatusCreated

	case http.MethodPut:
		response.Message = "PUT request processed successfully"
		response.Status = http.StatusOK

	case http.MethodDelete:
		response.Message = "DELETE request processed successfully"
		response.Status = http.StatusOK

	case http.MethodPatch:
		response.Message = "PATCH request processed successfully"
		response.Status = http.StatusOK

	case http.MethodOptions:
		response.Message = "OPTIONS request processed successfully"
		response.Status = http.StatusOK

	default:
		// Handle unsupported methods
		errorResp := ErrorResponse{
			Error:   "Method Not Allowed",
			Message: fmt.Sprintf("HTTP method %s is not supported", request.HTTPMethod),
			Status:  http.StatusMethodNotAllowed,
		}

		errorBody, _ := json.Marshal(errorResp)
		return events.ALBTargetGroupResponse{
			StatusCode: http.StatusMethodNotAllowed,
			Headers:    headers,
			Body:       string(errorBody),
		}, nil
	}

	// Marshal response to JSON
	responseBody, err := json.Marshal(response)
	if err != nil {
		log.Printf("Error marshaling response: %v", err)
		errorResp := ErrorResponse{
			Error:   "Internal Server Error",
			Message: "Failed to process request",
			Status:  http.StatusInternalServerError,
		}
		errorBody, _ := json.Marshal(errorResp)
		return events.ALBTargetGroupResponse{
			StatusCode: http.StatusInternalServerError,
			Headers:    headers,
			Body:       string(errorBody),
		}, nil
	}

	log.Printf("Sending response: %s", string(responseBody))

	return events.ALBTargetGroupResponse{
		StatusCode: response.Status,
		Headers:    headers,
		Body:       string(responseBody),
	}, nil
}

// convertToALBRequest converts an HTTP request to ALB request format
func convertToALBRequest(r *http.Request) events.ALBTargetGroupRequest {
	// Read request body
	body := ""
	if r.Body != nil {
		defer r.Body.Close()
		// For simplicity, we'll just read a limited amount
		buf := make([]byte, 1024)
		n, _ := r.Body.Read(buf)
		if n > 0 {
			body = string(buf[:n])
		}
	}

	// Convert headers
	headers := make(map[string]string)
	for key, values := range r.Header {
		if len(values) > 0 {
			headers[key] = values[0]
		}
	}

	// Convert query parameters
	queryParams := make(map[string]string)
	for key, values := range r.URL.Query() {
		if len(values) > 0 {
			queryParams[key] = values[0]
		}
	}

	return events.ALBTargetGroupRequest{
		HTTPMethod:            r.Method,
		Path:                  r.URL.Path,
		QueryStringParameters: queryParams,
		Headers:               headers,
		Body:                  body,
		IsBase64Encoded:       false,
		RequestContext: events.ALBTargetGroupRequestContext{
			ELB: events.ELBContext{
				TargetGroupArn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/1234567890123456",
			},
		},
	}
}

// startLocalServer starts a local HTTP server for development
func startLocalServer() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Convert HTTP request to ALB request format
		albRequest := convertToALBRequest(r)

		// Call the Lambda handler
		response, err := handleRequest(context.Background(), albRequest)
		if err != nil {
			log.Printf("Error handling request: %v", err)
			http.Error(w, "Internal Server Error", http.StatusInternalServerError)
			return
		}

		// Set response headers
		for key, value := range response.Headers {
			w.Header().Set(key, value)
		}
		w.WriteHeader(response.StatusCode)
		w.Write([]byte(response.Body))
	})

	log.Printf("Local server starting on port %s", port)
	log.Printf("Test with: curl -X GET http://localhost:%s/", port)
	log.Printf("Available endpoints:")
	log.Printf("  GET    http://localhost:%s/", port)
	log.Printf("  POST   http://localhost:%s/", port)
	log.Printf("  PUT    http://localhost:%s/", port)
	log.Printf("  DELETE http://localhost:%s/", port)
	log.Printf("  PATCH  http://localhost:%s/", port)
	log.Printf("  OPTIONS http://localhost:%s/", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

// main function is the entry point for the Lambda function
func main() {
	// Check if we're running in local development mode
	if os.Getenv("LOCAL_DEV") == "true" {
		startLocalServer()
	} else {
		// Run as Lambda function
		lambda.Start(handleRequest)
	}
}
