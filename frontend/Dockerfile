# Use Node.js to run React dev server
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Expose React dev server port
EXPOSE 3000

# Start React app directly
CMD ["npm", "start"]

