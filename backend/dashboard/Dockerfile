FROM node:18-alpine

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install dependencies - fail if this doesn't work
RUN npm install --production || npm install

# Copy all application files
COPY . .

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Set environment to use port 8080
ENV PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/splash.html', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }).on('error', () => process.exit(1));"

# Start the server
CMD ["node", "serve.js"]
