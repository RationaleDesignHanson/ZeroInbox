#!/bin/bash

# Production-ready service startup script for Zero backend
# This script ensures all services start cleanly and validates they're running

set -e  # Exit on any error

echo "🚀 Starting Zero Backend Services"
echo "=================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="/Users/matthanson/EmailShortForm_01/backend"
LOG_DIR="$BACKEND_DIR/logs"
PID_DIR="$BACKEND_DIR/pids"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$PID_DIR"

# Function to check if a port is in use
check_port() {
    local port=$1
    lsof -ti:$port > /dev/null 2>&1
}

# Function to kill process on a port
kill_port() {
    local port=$1
    local service_name=$2
    if check_port $port; then
        echo -e "${YELLOW}⚠️  Port $port already in use by $service_name, cleaning up...${NC}"
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=0

    echo -n "   Waiting for $service_name to be ready"

    while [ $attempt -lt $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done

    echo -e " ${RED}✗ (timeout)${NC}"
    return 1
}

# Clean up any existing processes
echo "1. Cleaning up existing processes..."
kill_port 3001 "API Gateway"
kill_port 8081 "Email Service"
kill_port 8082 "Classifier"
kill_port 8083 "Summarization"
kill_port 8084 "Smart Replies"
kill_port 8085 "Shopping Agent"
kill_port 8087 "Steel Agent"

# Kill any npm/node processes related to our services
pkill -9 -f "npm.*start" 2>/dev/null || true
pkill -9 -f "node.*services" 2>/dev/null || true
sleep 2

echo -e "${GREEN}✓${NC} Cleanup complete"
echo ""

# Start main backend services (API Gateway, Email, Classifier, Summarization)
echo "2. Starting core backend services..."
cd "$BACKEND_DIR"

USE_ACTION_FIRST=true npm run start:all > "$LOG_DIR/backend.log" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "$PID_DIR/backend.pid"

# Wait for each core service to be ready
wait_for_service "http://localhost:3001/health" "API Gateway (3001)" || exit 1
wait_for_service "http://localhost:8081/health" "Email Service (8081)" || exit 1
wait_for_service "http://localhost:8082/health" "Classifier (8082)" || exit 1
wait_for_service "http://localhost:8083/health" "Summarization (8083)" || exit 1
wait_for_service "http://localhost:8084/health" "Smart Replies (8084)" || exit 1

echo -e "${GREEN}✓${NC} Core services started (including Smart Replies)"
echo ""

# Start Shopping Agent service (port 8085)
echo "4. Starting Shopping Agent service..."
cd "$BACKEND_DIR/services/shopping-agent"
PORT=8085 node server.js > "$LOG_DIR/shopping-agent.log" 2>&1 &
SHOPPING_PID=$!
echo $SHOPPING_PID > "$PID_DIR/shopping-agent.pid"

wait_for_service "http://localhost:8085/health" "Shopping Agent (8085)" || exit 1

echo -e "${GREEN}✓${NC} Shopping Agent started"
echo ""

# Start Steel Agent service (port 8087)
echo "5. Starting Steel Agent service..."
cd "$BACKEND_DIR/services/steel-agent"
PORT=8087 node server.js > "$LOG_DIR/steel-agent.log" 2>&1 &
STEEL_PID=$!
echo $STEEL_PID > "$PID_DIR/steel-agent.pid"

wait_for_service "http://localhost:8087/health" "Steel Agent (8087)" || exit 1

echo -e "${GREEN}✓${NC} Steel Agent started"
echo ""

# Final health check
echo "6. Running final health checks..."
echo ""

ALL_HEALTHY=true

check_service() {
    local url=$1
    local name=$2
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅${NC} $name"
    else
        echo -e "   ${RED}❌${NC} $name"
        ALL_HEALTHY=false
    fi
}

check_service "http://localhost:3001/health" "API Gateway (3001)"
check_service "http://localhost:8081/health" "Email Service (8081)"
check_service "http://localhost:8082/health" "Classifier (8082)"
check_service "http://localhost:8083/health" "Summarization (8083)"
check_service "http://localhost:8084/health" "Smart Replies (8084)"
check_service "http://localhost:8085/health" "Shopping Agent (8085)"
check_service "http://localhost:8087/health" "Steel Agent (8087)"

echo ""

if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}=================================="
    echo "✅ All services started successfully!"
    echo "==================================${NC}"
    echo ""
    echo "Service URLs:"
    echo "  • API Gateway:    http://localhost:3001"
    echo "  • Email Service:  http://localhost:8081"
    echo "  • Classifier:     http://localhost:8082"
    echo "  • Summarization:  http://localhost:8083"
    echo "  • Smart Replies:  http://localhost:8084"
    echo "  • Shopping Agent: http://localhost:8085"
    echo "  • Steel Agent:    http://localhost:8087"
    echo ""
    echo "Logs directory: $LOG_DIR"
    echo "PIDs directory: $PID_DIR"
    echo ""
    echo "To stop all services, run: ./stop-services.sh"
    echo ""
    exit 0
else
    echo -e "${RED}=================================="
    echo "❌ Some services failed to start"
    echo "==================================${NC}"
    echo ""
    echo "Check logs in: $LOG_DIR"
    echo ""
    exit 1
fi
