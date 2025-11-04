FROM node:18-alpine

WORKDIR /app

# Copy package files first (if they exist)
COPY package*.json ./

# Install dependencies
RUN npm install --production 2>/dev/null || npm install express 2>/dev/null || true

# Copy all application files
COPY . .

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Set environment to use port 8080
ENV PORT=8080

# Start the server
CMD ["node", "serve.js"]
