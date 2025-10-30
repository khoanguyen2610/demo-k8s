# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build production bundle
RUN npm run build

# Production stage - Node.js static server (no nginx!)
FROM node:18-alpine

WORKDIR /app

# Install 'serve' - simple static file server
RUN npm install -g serve

# Copy built files from builder
COPY --from=builder /app/build ./build

# Expose port
EXPOSE 3000

# Serve static files (fast and simple!)
CMD ["serve", "-s", "build", "-l", "3000"]

