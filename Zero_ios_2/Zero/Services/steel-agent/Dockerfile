# Steel Agent Service Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm install --only=production

# Copy shared modules
COPY shared/ ./shared/

# Copy steel-agent service
COPY services/steel-agent/ ./services/steel-agent/

# Copy subscription helper
COPY services/subscriptions/ ./services/subscriptions/

# Expose port
EXPOSE 8087

# Set environment
ENV NODE_ENV=production
ENV PORT=8087

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8087/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start service
CMD ["node", "services/steel-agent/server.js"]
