FROM node:18-alpine

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY *.js ./
COPY *.md ./

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Set environment to use port 8080
ENV PORT=8080

# Start the server
CMD ["node", "server.js"]
