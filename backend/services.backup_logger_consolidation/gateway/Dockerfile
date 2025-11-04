FROM node:18-alpine

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies (including googleapis)
RUN npm ci --only=production

# Copy application files
COPY shared/ ./shared/
COPY routes/ ./routes/
COPY server.js ./
COPY VERSION ./VERSION

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Set environment to use port 8080
ENV PORT=8080

# Start the server
CMD ["node", "server.js"]
