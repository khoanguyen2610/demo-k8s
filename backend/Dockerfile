# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the API application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o api-server .

# Build the consumer application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o consumer ./cmd/consumer

# Final stage - API Server
FROM alpine:latest AS api

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the API binary from builder
COPY --from=builder /app/api-server .

# Expose port
EXPOSE 8080

# Run the API application
CMD ["./api-server"]

# Final stage - Consumer
FROM alpine:latest AS consumer

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the consumer binary from builder
COPY --from=builder /app/consumer .

# Run the consumer application (task name should be passed as argument)
ENTRYPOINT ["./consumer"]

