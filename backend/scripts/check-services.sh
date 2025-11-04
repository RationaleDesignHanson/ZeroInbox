#!/bin/bash

# Quick health check script for all Zero backend services

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo "🔍 Zero Backend Services Health Check"
echo "======================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

ALL_HEALTHY=true

# Check Google Cloud credentials
echo -e "${BLUE}Configuration Checks:${NC}"
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        echo -e "${GREEN}✅${NC} Google Cloud credentials configured"
        echo -e "   ${BLUE}ℹ️  ${GOOGLE_APPLICATION_CREDENTIALS}${NC}"
    else
        echo -e "${YELLOW}⚠️${NC}  GOOGLE_APPLICATION_CREDENTIALS path not found"
        echo -e "   Summarization may fail to call Vertex AI"
    fi
else
    echo -e "${YELLOW}⚠️${NC}  GOOGLE_APPLICATION_CREDENTIALS not set"
    echo -e "   Summarization will use default credentials"
fi
echo ""

check_service() {
    local url=$1
    local name=$2
    local port=$3

    if curl -s --max-time 2 "$url" > /dev/null 2>&1; then
        local status=$(curl -s "$url" | jq -r '.status // "healthy"' 2>/dev/null || echo "ok")
        echo -e "${GREEN}✅${NC} $name - Status: $status"
    else
        echo -e "${RED}❌${NC} $name - NOT RESPONDING"
        ALL_HEALTHY=false

        # Check if port is in use
        if lsof -ti:$port > /dev/null 2>&1; then
            echo -e "   ${YELLOW}⚠️  Port $port is in use but service not responding${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Port $port is not in use - service not started${NC}"
        fi
    fi
}

# Check each service
check_service "http://localhost:3001/health" "API Gateway (3001)" 3001
check_service "http://localhost:8081/health" "Email Service (8081)" 8081
check_service "http://localhost:8082/health" "Classifier (8082)" 8082
check_service "http://localhost:8083/health" "Summarization (8083)" 8083
check_service "http://localhost:8085/health" "Shopping Agent (8085)" 8085

# Smart Replies doesn't have a health endpoint, just check if port is listening
echo -n "Smart Replies (8084) - "
if lsof -ti:8084 > /dev/null 2>&1; then
    echo -e "${GREEN}✅${NC} Port listening"
else
    echo -e "${RED}❌${NC} NOT RUNNING"
    ALL_HEALTHY=false
fi

echo ""
echo "======================================"

if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}✅ All services are healthy${NC}"
    exit 0
else
    echo -e "${RED}❌ Some services have issues${NC}"
    echo ""
    echo "To restart services, run:"
    echo "  ./stop-services.sh && ./start-services.sh"
    exit 1
fi
